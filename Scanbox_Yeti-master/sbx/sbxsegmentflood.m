function varargout = sbxsegmentflood(varargin)
% SBXSEGMENTFLOOD MATLAB code for sbxsegmentflood.fig
%      SBXSEGMENTFLOOD, by itself, creates a new SBXSEGMENTFLOOD or raises the existing
%      singleton*.
%
%      H = SBXSEGMENTFLOOD returns the handle to a new SBXSEGMENTFLOOD or the handle to
%      the existing singleton*.
%
%      SBXSEGMENTFLOOD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SBXSEGMENTFLOOD.M with the given input arguments.
%
%      SBXSEGMENTFLOOD('Property','Value',...) creates a new SBXSEGMENTFLOOD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sbxsegmentflood_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sbxsegmentflood_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sbxsegmentflood

% Last Modified by GUIDE v2.5 04-Oct-2014 17:05:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @sbxsegmentflood_OpeningFcn, ...
    'gui_OutputFcn',  @sbxsegmentflood_OutputFcn, ...
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


% --- Executes just before sbxsegmentflood is made visible.
function sbxsegmentflood_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sbxsegmentflood (see VARARGIN)

% Choose default command line output for sbxsegmentflood
handles.output = hObject;

% Update handles structure

% UIWAIT makes sbxsegmentflood wait for user response (see UIRESUME)
% uiwait(handles.figure1);

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = sbxsegmentflood_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadbtn.
function loadbtn_Callback(hObject, eventdata, handles)
% hObject    handle to loadbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.start_time = tic;
    cla;
    hold off;
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
    catch
        handles.xray = [];
    end
    set(handles.xraychk,'visible','off');
    set(handles.xraychk,'value',0);
    set(handles.histeq,'visible','on');
    
    try
        load([fn(1:end-6) '.segment'],'-mat');
        handles.mask = mask;
    catch
        handles.mask = zeros(size(handles.m));
    end
    handles.npixels = 250;
    handles.floodcenter = [];
    handles.fn = fn;
    
    %set(gca,'Xlim',[.5,size(handles.m,2)-.5]);
    %set(gca,'ylim',[.5,size(handles.m,1)-.5]);

    axis tight;
    zoom off;
    pan off;
    
    hold on;
    handles.im_mask = image(bsxfun(@times,ones(size(handles.m)),reshape([0,0,1],[1,1,3])));
    %set(gca,'Xlim',[.5,size(handles.m,2)-.5]);
    %set(gca,'ylim',[.5,size(handles.m,1)-.5]);
    
    handles.im_flood = image(bsxfun(@times,ones(size(handles.m)),reshape([1,0,0],[1,1,3])));
    set(gca,'Xlim',[.5,size(handles.m,2)-.5]);
    set(gca,'ylim',[.5,size(handles.m,1)-.5]);
    set(handles.im_flood,'visible','off');
    
    guidata(hObject, handles);
    
    
    
    drawbgim(handles);
    drawfgim(handles);
    %drawfloodim(handles);
    
    %check if there is a segment file
    %set(handles.im,'ButtonDownFcn',@(x,y) figure1_ButtonDownFcn(x,y,handles));
    set(handles.im_mask,'ButtonDownFcn',@(x,y) figure1_ButtonDownFcn(x,y,handles));
    set(handles.im_flood,'ButtonDownFcn',@(x,y) im_flood_ButtonDownFcn(x,y));
    
    refresh_stats(handles)

function refresh_stats(handles)
    nrois = max(handles.mask(:));
    ntime = toc(handles.start_time);
    thestr = sprintf('%d ROIS\n% 2d:%02d\n%.1fs/ROI',nrois,floor(ntime/60),mod(round(ntime),60),ntime/(nrois+.01));
    set(handles.stats,'String',thestr);
    
function im_flood_ButtonDownFcn(hObject, eventdata)
    handles = guidata(hObject);
    newmask = handles.floodmap < handles.npixels;
    handles.mask = handles.mask + (max(handles.mask(:))+1)*newmask;
    
    handles.floodcenter = [];
    guidata(hObject,handles);
    drawfgim(handles);
    drawfloodim(handles);
    set(handles.xraychk,'Value',1)

    set(handles.im_flood,'Visible','off');
    
    refresh_stats(handles);
    
function drawfgim(handles)
    if get(handles.hiderois,'Value')
        themask = zeros(size(handles.mask));
    else
        themask = handles.mask > 0;
    end
    set(handles.im_mask,'AlphaData',.5*(themask));
    
    
function drawfloodim(handles)
    if ~isempty(handles.floodcenter)
        %Pick the target image
        
        %Flood fill
        floodim = handles.floodmap<handles.npixels;
        set(handles.im_flood,'AlphaData',.5*(floodim));
    end
        


% --- Executes on button press in ffbtn.
function ffbtn_Callback(hObject, eventdata, handles)
% hObject    handle to ffbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

zoom off
pan off
set(handles.im_flood,'Visible','off')
handles.xraypoint = [];
set(handles.xraychk,'Value',1)
guidata(hObject, handles);
drawbgim(handles)


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

% --- Executes on button press in savebtn.
function savebtn_Callback(hObject, eventdata, handles)
% hObject    handle to savebtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


zoom off;
pan off;

mask = handles.mask;

%create vertices from mask
vert = cell(max(mask(:)),1);
for ii = 1:max(mask(:))
    try
        vert{ii} = mask2poly(mask==ii,'Inner','MinDist');
    catch me
        vert{ii} = [];
    end
end

save([strtok(handles.fn,'.') '.segment'],'mask','vert');
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

    %try a 100 different positions

        if ~isempty(handles.xraypoint)
            theim = pastexrayintoim(theim,handles);
            %M1 = theim0(round(handles.xraypoint(2)) + (-30:30),...
            %            round(handles.xraypoint(1)) + (-30:30));
            %M2 = theim(round(handles.xraypoint(2)) + (-30:30),...
            %           round(handles.xraypoint(1)) + (-30:30));
            %corr(M1(:),M2(:))
        end
    
    set(handles.im,'Cdata',theim);
    colormap(gray);
    axis off;
    
function theim = pastexrayintoim(theim,handles)
    sz = size(handles.xray,3);
    thefactor = round(size(theim,2)/size(handles.xray,2));

    handles.xraypoint = max(handles.xraypoint,1);
    handles.xraypoint(1) = min(handles.xraypoint(1),size(theim,2));
    handles.xraypoint(2) = min(handles.xraypoint(2),size(theim,1));
    dx = -floor(handles.xraypoint(2:-1:1)/thefactor)*thefactor+sz*thefactor/2;
    dx(1) = dx(1) - 1;
    dx(2) = dx(2) - 1;
    theim0 = theim;
    theim = circshift(theim,dx);

    R = squeeze(handles.xray(max(floor(handles.xraypoint(2)/thefactor),1),...
                             max(floor(handles.xraypoint(1)/thefactor),1),:,:));
    if thefactor == 2
        R2 = zeros(size(R,1)*2-1,size(R,2)*2-1);
        R2(1:2:end,1:2:end) = R;
        R2 = conv2([.5,1,.5],[.5,1,.5],R2,'same');
        A = R2(2:end-1,2:end-1);
    end
    %A = imresize(R,thefactor);
    R(ceil(end/2),ceil(end/2)) = 0;
    rg = (1:size(A,1));
    theim(rg,rg) = A/(max(R(:))+.01);
    theim = circshift(theim,-dx);

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
handles = guidata(hObject);
if(get(handles.xraychk,'Value'))
    set(handles.xraychk,'Value',0)
    a = get(handles.axes1,'CurrentPoint');
    a = round(a(1,1:2)');
    handles.floodcenter = max(a,1);
    set(handles.im_flood,'Visible','on');
    
    B = computefloodim(handles);
    handles.floodmap = B;
    
    guidata(hObject, handles);
    drawfgim(handles);
    drawfloodim(handles);
end

function B = computefloodim(handles)
    if isempty(handles.xray)
        theim = handles.m;
        thecen = round(handles.floodcenter);
    else
        theim = zeros(size(handles.m));
        theim = pastexrayintoim(theim,handles);
        thecen = round(handles.floodcenter(2:-1:1));
    end
    
    theim = theim.*(handles.mask==0);
    
    [~,B] = regiongrowing(theim,thecen(1),thecen(2),nnz(theim(:)));


%{
if get(handles.xraychk,'Value')
    a = get(handles.axes1,'CurrentPoint');
    handles.xraypoint = round(a(:,1:2)');
    handles.is
    guidata(hObject, handles);
    drawbgim(handles)
    set(handles.xraychk,'Value',0);
end
%}


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


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over xraybtn.
function xraybtn_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to xraybtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over ffbtn.
function ffbtn_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ffbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.xraychk,'Value',1)


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
handles.npixels = max(10,handles.npixels - (eventdata.VerticalScrollAmount*eventdata.VerticalScrollCount)*15);
guidata(hObject,handles);
drawfloodim(handles);


% --- Executes on button press in undobtn.
function undobtn_Callback(hObject, eventdata, handles)
% hObject    handle to undobtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
themax = max(handles.mask(:));
handles.mask(handles.mask==themax) = 0;
guidata(hObject,handles);
drawfgim(handles);
drawfloodim(handles);
refresh_stats(handles);

% --- Executes on button press in hiderois.
function hiderois_Callback(hObject, eventdata, handles)
% hObject    handle to hiderois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hiderois
drawfgim(handles);
