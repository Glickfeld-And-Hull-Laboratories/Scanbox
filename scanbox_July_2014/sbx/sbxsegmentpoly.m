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

% Last Modified by GUIDE v2.5 10-Dec-2013 14:18:49

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
guidata(hObject, handles);

% UIWAIT makes sbxsegmentpoly wait for user response (see UIRESUME)
% uiwait(handles.figure1);


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

plist = {};
h = [];

fn = uigetfile('*.align');

load(fn,'-mat');

m = double(m);
m = (m-min(m(:)))/(max(m(:))-min(m(:)));

axis(handles.axes1);
imagesc(adapthisteq(m,'NumTiles',[16 16],'Distribution','Exponential'));
colormap(gray);
axis off;

% check if there is a segment file

[a,b] =strtok(fn,'.');
if(exist([a '.segment'],'file'))
    load([a '.segment'],'vert','-mat');
    ch = get(gca,'children');
    for(i=1:length(vert))
        plist{i} = impoly(gca,vert{i});
        drawnow;
    end
    
end



% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global h plist;

zoom off;
pan off;

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


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

zoom off;
pan on;


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
    mask(plist{i}.createMask)=i;
    vert{i} = plist{i}.getPosition;
end

save([strtok(fn,'.') '.segment'],'mask','vert');


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

axis off;
