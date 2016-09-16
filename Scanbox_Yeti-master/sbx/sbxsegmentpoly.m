function varargout = sbxsegmentpoly(varargin)
% SBXSEGMENTPOLY MATLAB code for sbxsegmentpoly.fig
%      SBXSEGMENTPOLY, by itself, creates a new SBXSEGMENTPOLY or raises the existing
%      singleton*.
%
%      H = SBXSEGMENTPOLY returns the handle to a new SBXSEGMENTPOLY or the handle to
%      the existing singleton*.
%
%      SBXSEGMENTPOLY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SBXSEGMENTPOLY.M with the given input arguments.
%
%      SBXSEGMENTPOLY('Property','Value',...) creates a new SBXSEGMENTPOLY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sbxsegmentpoly_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sbxsegmentpoly_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sbxsegmentpoly

% Last Modified by GUIDE v2.5 02-Oct-2014 22:08:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @sbxsegmentpoly_OpeningFcn, ...
    'gui_OutputFcn',  @sbxsegmentpoly_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before sbxsegmentpoly is made visible.
function sbxsegmentpoly_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sbxsegmentpoly (see VARARGIN)

% Choose default command line output for sbxsegmentpoly
handles.output = hObject;

% Update handles structure

% UIWAIT makes sbxsegmentpoly wait for user response (see UIRESUME)
% uiwait(handles.figure1);

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = sbxsegmentpoly_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global m T plist h fn;

cla;    
zoom off;
pan off;
set(handles.xraychk,'Value',0);
handles.xraypoint = [];

    plist = {};
    h = [];
    
    [fn,pathname] = uigetfile('*.align');
    fn = [pathname fn];
    
    text(0.5,0.5,'loading...');
    axis([0,1,0,1]);
    drawnow
    try 
        load(fn,'-mat');
    catch
        return
    end
    
    axis off
    handles.im = imagesc(0,[0,1]);
    
    m = double(m);
    m = (m-min(m(:)))/(max(m(:))-min(m(:)));
    
    try
        handles.c3 = c3;
        g = exp(-(-50:50)/2/8^2);
        g = g/sum(g(:));
        A = convn(convn(c3,g,'same'),g','same');
        c3_eq =c3./(.01+A);
        handles.c3_eq = adapthisteq(c3_eq/max(c3_eq(:)),'NumTiles',[16 16],'Distribution','Exponential');
        
        %Kurtosis
        k = min(max(k,0).^.5,20);
        handles.k = k/max(k(:));
        
        sm = bsxfun(@times,sm,1./median(sm))-.5;
        handles.sm = sm/max(sm(:));
        
        A = convn(convn(k,g,'same'),g','same');
        B = conv2(g,g,ones(size(sm)),'same');
        A = A./B;
        A = sqrt(k./(.001+A));
        A = real(A);
        handles.k_eq = adapthisteq(A/max(A(:)),'NumTiles',[16 16],'Distribution','Exponential');
        
        %Max
        A = conv2(g,g,sm,'same');
        B = conv2(g,g,ones(size(sm)),'same');
        A = A./B;
        A = sm./(.01+A);
        handles.sm_eq = adapthisteq(A/max(A(:)),'NumTiles',[16 16],'Distribution','Exponential');
        
        %set(handles.corr,'Value',1);
        set(handles.histeq,'Value',0);
        set(handles.corr,'visible','on');
    catch
        %set(handles.corr,'Value',0);
        %set(handles.corr,'visible','off');
    end
    handles.m = m;
    handles.m_eq = adapthisteq(handles.m,'NumTiles',[16 16],'Distribution','Exponential');
    handles.xraypoint = [];
    try
        if isa(xray,'int16');
            xray = single(xray)/2^15;
        end
        handles.xray = xray;
        set(handles.xraybtn,'visible','on');
    catch
        set(handles.xraybtn,'visible','off');
    end
    set(handles.xraychk,'visible','off');
    set(handles.xraychk,'value',0);
    set(handles.histeq,'visible','on');
    
    guidata(hObject, handles);
    
    
    drawbgim(handles);
    axis tight;
    zoom off;
    pan off;
    
    %check if there is a segment file
    drawnow;
    [a,b] =strtok(fn,'.');
    if(exist([a '.segment'],'file'))
        load([a '.segment'],'vert','-mat');
        ch = get(gca,'children');
        n = 1;
        for(i=1:length(vert))
            if ~isempty(vert{i})
            %
                plist{n} = impoly(gca,vert{i});
                n = n + 1;
                drawnow
                %vert{i}
            end
        end
    end


    set(handles.im,'ButtonDownFcn',@(x,y) figure1_ButtonDownFcn(x,y,handles));
%{
else
       
    plist = {};
    h = [];
    
    fn = uigetfile('*.align');
    
    load(fn,'-mat');
    
    [a,b] =strtok(fn,'.');
    z = sbxread(a,1,1);
    global info;
    z = sbxreadskip(a,200,floor(info.max_idx/200));
    z = squeeze(z);
    z = zscore(double(z),[],3);
    
    C = zeros(size(z,1),size(z,2));
    for(i=2:size(z,1)-1)
        i
        for(j=2:size(z,2))
            c = zeros(3);
            m = -inf;
            for(k=-1:1)
                for(m=-1:1)
                    if(k~=0 || m~=0)
                        a = squeeze(z(i,j,:))' * squeeze(z(i+k,i+m,:));
                        if(a>m)
                            m=a;
                        end
                    end
                end
            end
            C(i,j) = m;
        end
    end
    
   
    m = double(m);
    m = (m-min(m(:)))/(max(m(:))-min(m(:)));
    
    axis(handles.axes1);
    imagesc(adapthisteq(m,'NumTiles',[16 16],'Distribution','Exponential'));
    colormap(gray);
    axis off;
    
    check if there is a segment file
    
    [a,b] =strtok(fn,'.');
    if(exist([a '.segment'],'file'))
        load([a '.segment'],'vert','-mat');
        ch = get(gca,'children');
        for(i=1:length(vert))
            plist{i} = impoly(gca,vert{i});
            drawnow;
        end
    end
end
%}



% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global h plist;

zoom off;
pan off;

set(handles.xraychk,'Value',0)

if(~isempty(h))
    plist{end+1} = h;
end

h = impoly;


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global h;

try,
    h.delete;
    h = [];
catch
end


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pan off;
zoom on;
set(handles.xraychk,'Value',0)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

zoom off;
pan on;
set(handles.xraychk,'Value',0)

%{

global fn
for ii = 1:18000
    D = sbxreadpacked(fn(1:end-6),ii-1,1);
    set(handles.im,'Cdata',double(D)/(2^16));
    drawnow;
end
%}

% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global m plist fn h;

zoom off;
pan off;

if(~isempty(h))
    plist{end+1} = h;
end

h = [];

mask = zeros(size(m));
vert = cell(1,length(plist));
for(i=1:length(plist))
    try
        mask(plist{i}.createMask)=i;
        vert{i} = plist{i}.getPosition;
    catch me
        %Sometimes single vertices stop the thing from being saved
        continue
    end
end

save([strtok(fn,'.') '.segment'],'mask','vert');
fprintf('Saved segments\n');


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

axis off;


% --- Executes on button press in corr.
function corr_Callback(hObject, eventdata, handles)
% hObject    handle to corr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of corr
handles.xraypoint = [];
guidata(hObject, handles);
drawbgim(handles)

function drawbgim(handles)
axis(handles.axes1);

thesel = get(handles.corr,'SelectedObject');
thesel = get(thesel,'Tag');
if get(handles.histeq,'Value') == 0
    switch thesel
        case 'rb_corr'
            theim = handles.c3;
        case 'rb_m'
            theim = handles.m;
        case 'rb_them'
            theim = handles.sm;
        case 'rb_k'
            theim = handles.k;
    end
else
    switch thesel
        case 'rb_corr'
            theim = handles.c3_eq;
        case 'rb_m'
            theim = handles.m_eq;
        case 'rb_them'
            theim = handles.sm_eq;
        case 'rb_k'
            theim = handles.k_eq;
    end
end

try
    if ~isempty(handles.xraypoint)
        sz = size(handles.xray,3);
        thefactor = round(size(theim,2)/size(handles.xray,2));
        
        handles.xraypoint = max(handles.xraypoint,thefactor/2);
        handles.xraypoint(1) = min(handles.xraypoint(1),size(theim,2));
        handles.xraypoint(2) = min(handles.xraypoint(2),size(theim,1));
        dx = -round(handles.xraypoint(2:-1:1)/thefactor)*thefactor+sz*thefactor/2;
        theim = circshift(theim,dx);
        rg = (1:sz*thefactor);
        R = squeeze(handles.xray(round(handles.xraypoint(2)/thefactor),round(handles.xraypoint(1)/thefactor),:,:));
        A = imresize(R,thefactor);
        R(ceil(end/2),ceil(end/2)) = 0;
        theim(rg,rg) = A/(max(R(:))+.01);
        theim = circshift(theim,-dx);
    end
catch
    
end
set(handles.im,'Cdata',theim);
colormap(gray);
axis off;
    


% --- Executes on button press in histeq.
function histeq_Callback(hObject, eventdata, handles)
% hObject    handle to histeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of histeq
handles.xraypoint = [];
guidata(hObject, handles);
drawbgim(handles)



% --- Executes on button press in xraybtn.
function xraybtn_Callback(hObject, eventdata, handles)
% hObject    handle to xraybtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zoom off
pan off
handles.xraypoint = [];
set(handles.xraychk,'Value',1)
guidata(hObject, handles);
drawbgim(handles)

%ginput(1);


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.xraychk,'Value')
    a = get(handles.axes1,'CurrentPoint');
    handles.xraypoint = round(a(:,1:2)');
    guidata(hObject, handles);
    drawbgim(handles)
    
end


% --- Executes on button press in xraychk.
function xraychk_Callback(hObject, eventdata, handles)
% hObject    handle to xraychk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of xraychk
handles.xraypoint = [];
guidata(hObject, handles);
drawbgim(handles)


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.xraychk,'Value')
    a = get(handles.axes1,'CurrentPoint');
    handles.xraypoint = round(a(:,1:2)');
    guidata(hObject, handles);
    drawbgim(handles)
    set(handles.xraychk,'Value',0);
end


% --- Executes when selected object is changed in corr.
function corr_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in corr 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
handles.xraypoint = [];
guidata(hObject, handles);
drawbgim(handles)
