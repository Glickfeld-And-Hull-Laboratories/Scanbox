function varargout = sbxaligntool(varargin)
% SBXALIGNTOOL MATLAB code for sbxaligntool.fig
%      SBXALIGNTOOL, by itself, creates a new SBXALIGNTOOL or raises the existing
%      singleton*.
%
%      H = SBXALIGNTOOL returns the handle to a new SBXALIGNTOOL or the handle to
%      the existing singleton*.
%
%      SBXALIGNTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SBXALIGNTOOL.M with the given input arguments.
%
%      SBXALIGNTOOL('Property','Value',...) creates a new SBXALIGNTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sbxaligntool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sbxaligntool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sbxaligntool

% Last Modified by GUIDE v2.5 05-Feb-2016 10:38:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sbxaligntool_OpeningFcn, ...
                   'gui_OutputFcn',  @sbxaligntool_OutputFcn, ...
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


% --- Executes just before sbxaligntool is made visible.
function sbxaligntool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sbxaligntool (see VARARGIN)

% Choose default command line output for sbxaligntool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes sbxaligntool wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = sbxaligntool_OutputFcn(hObject, eventdata, handles) 
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

[FileName,PathName] = uigetfile('*sbx');
cd(PathName);
strtok(FileName,'.')
z = sbxread(strtok(FileName,'.'),1,50);
z = squeeze(z(1,:,:,:));
axes(handles.axes1);
handles.img = imagesc(squeeze(mean(z,length(size(z)))));
axis off;
colormap gray




% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

points = detectBRISKFeatures(handles.axes1.Children.CData,'MinQuality',0.2,'MinContrast',0.4);


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global L F;
sz = str2num(handles.sz.String);
L{end+1} = imrect(handles.axes1,[10 10 sz sz]);
wait(L{end});
p = round(L{end}.getPosition);
x = p(1):p(1)+p(3)-1;
y = p(2):p(2)+p(4)-1;
F{end+1} = fft2(handles.axes1.Children(end).CData(y,x));


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1
hObject.Visible = 'off';


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

imcontrast(handles.axes1);



function sz_Callback(hObject, eventdata, handles)
% hObject    handle to sz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sz as text
%        str2double(get(hObject,'String')) returns contents of sz as a double


% --- Executes during object creation, after setting all properties.
function sz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
