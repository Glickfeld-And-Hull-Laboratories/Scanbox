function varargout = scanbox(varargin)
% SCANBOX MATLAB code for scanbox.fig
%      SCANBOX, by itself, creates a new SCANBOX or raises the existing
%      singleton*.
%
%      H = SCANBOX returns the handle to a new SCANBOX or the handle to
%      the existing singleton*.
%
%      SCANBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCANBOX.M with the given input arguments.
%
%      SCANBOX('Property','Value',...) creates a new SCANBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before scanbox_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to scanbox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help scanbox

% Last Modified by GUIDE v2.5 24-Jul-2014 09:19:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @scanbox_OpeningFcn, ...
    'gui_OutputFcn',  @scanbox_OutputFcn, ...
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


% --- Executes just before scanbox is made visible.
function scanbox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to scanbox (see VARARGIN)

% Choose default command line output for scanbox
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Make sure ethernet connection to outside world is disabled...

[~, ~] = system('netsh interface set interface "Local Area Connection" DISABLED');

% Config options...

% Run the lines in the config file

h = figure(10); %create flash window...
p = WindowAPI(h,'monitor');
WindowAPI(h,'Position',[p.Position(3:4)/2 - [200 100] 400 200])
WindowAPI(h,'Alpha',0.9)
WindowAPI(h,'Clip')
WindowAPI(h,'TopMost')
sbt = text(0.5, 0.5, 'Scanbox 1.2', ...
    'Units',    'normalized', ...
    'FontSize', 24, ...
    'HorizontalAlignment', 'center', ...
    'Margin',   12);
axis off;

pause(1);

set(sbt,'FontSize',18,'Color',[0.8 0.1 0.1]);
set(sbt,'String','Reading configuration file...'); drawnow;

fid = fopen('C:\scanbox\scanbox_config.m');
cmd = fgetl(fid);
while(cmd ~= -1)
    eval(cmd);
    cmd = fgetl(fid);
end
fclose(fid);

global sbconfig;

% scanbox_config;

% gray out optional boxes...

set(sbt,'String','Setting panels...'); drawnow;

if(sbconfig.optotune == 0)
    ch = get(handles.otpanel,'children');
    for(i=1:length(ch))
        try
            set(ch(i),'Enable','off');
        catch
        end
    end
end

if(sbconfig.balltracker == 0)
    ch = get(handles.ballpanel,'children');
    for(i=1:length(ch))
        try
            set(ch(i),'Enable','off');
        catch
        end
    end
end


if(sbconfig.eyetracker == 0)
    ch = get(handles.eyepanel,'children');
    for(i=1:length(ch))
        try
            set(ch(i),'Enable','off');
        catch
        end
    end
end

if(isempty(sbconfig.laser_type))
    ch = get(handles.uipanel11,'children');
    for(i=1:length(ch))
        try
            set(ch(i),'Enable','off');
        catch
        end
    end
    set(handles.lstatus,'String','Use the laser''s GUI for control');
    set(handles.pushbutton48,'Enable','on');
    set(handles.pushbutton49,'Enable','on');
end

% delete any hanging communication objects

set(sbt,'String','Initializing instruments'); drawnow;

delete(instrfindall);
pause(0.2);

global sb tri laser optotune sb_server

sb = [];
tri = [];
laser = [];
optotune = [];
sb_server = [];

% Open communication lines

set(sbt,'String','Opening scanbox'); drawnow;
sb_open;

set(sbt,'String','Set interrupt mask'); drawnow;
sb_imask(sbconfig.imask);

set(sbt,'String','Opening motor controller'); drawnow;
tri_open;

set(sbt,'String','Opening laser'); drawnow;

try
    laser_open;
catch
    delete(10)
    error('Scanbox:LaserComm', ...
        '\nCannot communicate with laser!\nPlease check:\n -Serial cable\n -COM port in scanbox_config\n\n');
end

set(sbt,'String','Opening socket'); drawnow;
udp_open;

set(sbt,'String','Opening Optotune'); drawnow;
ot_open;
ot_mode('D');

set(sbt,'String','Moving mirror in place'); drawnow;

sb_mirror(1);       % move mirror out of the way...

warning('off');

% ttlonline

global ttlonline;
ttlonline=0;

% motor variables init...

global axis_sel origin motor_gain mstep dmpos motormode mpos;

motormode = 1; % normal

motor_gain = [(2000/400/32)/2  ((.02*25400)/400/64)  ((.02*25400)/400/64) (0.0225/64)];  % z x y th

axis_sel = 2; % select x axis to begin with

mstep = [500 2000 2000 500];  % initialize with step sizes for coarse...


% % reset the memories...
% 
% for(j=1:4)
%     for(i=0:3)
%         tri_send('CCO',3,i,0);
%     end
% end

% set velocity and acceleration for motor 4 to control laser power

r = tri_send('SAP',4,4,2000);        %% set max vel and acc
r = tri_send('SAP',5,4,2000);

try
    for(i=0:3)
        r = tri_send('MVP',1,i,0);       %% zero and set origin
        origin(i+1) = r.value;
        r = tri_send('SAP',4,i,2000);    %% max vel accel
        r = tri_send('SAP',5,i,380);
    end
catch
    delete(10)
    error('Scanbox:MotorComm', ...
        '\nCannot communicate with motor controller!\nPlease check:\n -Serial cable\n -COM port in scanbox_config\n -Power cycle controller\n\n');
end


dmpos = origin;                      %% desired motor position is the same as the origin

mpos = cell(1,4);                      %% reset memory
for(i=1:4)
    mpos{i} = dmpos;
end


set(handles.xpos,'String','0.00')
set(handles.ypos,'String','0.00')
set(handles.zpos,'String','0.00')
set(handles.thpos,'String','0.00')

% z-stack

global z_top z_bottom z_steps z_size z_vals;

z_top = 0;
z_bottom = 0;
z_steps = 0;
z_vals = 0;

% ball tracker initialization
%

set(sbt,'String','Initializing image acquisition'); drawnow;

imaqreset;
imaqmem(sbconfig.imaqmem);       % set 4GB of memory...

set(sbt,'String','Setting up cameras'); drawnow;

set(sbt,'String','Getting camera information'); drawnow;

q = imaqhwinfo('gige');

set(sbt,'String','Configuring ball camera'); drawnow;


if(sbconfig.balltracker)
    
    global wcam wcam_src wcam_roi;
    
    %     wcam = videoinput('winvideo', 1, 'I420_160x120');
    %     wcam_src = getselectedsource(wcam);
    %
    %     wcam.FramesPerTrigger = inf;
    %     wcam.ReturnedColorspace = 'grayscale';
    %
    %     wcam_src.ExposureMode = 'manual';
    %     wcam_src.Exposure = -6;
    %     wcam_src.Sharpness = 255;
    %     wcam_src.FocusMode = 'manual';
    %     wcam_src.Focus = 25;
    %     wcam_src.FrameRate = '30.0000';
    
    for(i=1:length(q.DeviceInfo))
        if(~isempty(strfind(q.DeviceInfo(i).DeviceName,'M640')))  %% search for 1410 genie camera
            break;
        end
    end
    
    wcam = videoinput('gige', i, 'Mono8');
    wcam_src = getselectedsource(wcam);
    wcam_src.ReverseX = 'False';
    wcam_src.BinningHorizontal = 2;
    wcam_src.BinningVertical = 2;
    wcam_src.ExposureTimeAbs = 7000;
    wcam.FramesPerTrigger = inf;
    wcam.ReturnedColorspace = 'grayscale';
    wcam_src.AcquisitionFrameRateAbs = 30.0;
    wcam_roi = [0 0 wcam.VideoResolution];
    
    
    
    global ballarrow ballpos ttl0 ttl1;
    
    %     We are now streaming to disk...
    
    %     bpos = get(handles.ballpanel,'position');
    %
    %     ballpos(1) = bpos(1)+bpos(3)*0.5;
    %     ballpos(2) = bpos(2)+bpos(4)*0.4;
    %
    %     ballarrow = annotation('arrow',[ballpos(1) ballpos(1)],[ballpos(2) ballpos(2)],'headlength',5,'headstyle','vback1');
    
end

% dalsa config

set(sbt,'String','Configuring camera path'); drawnow;

if(sbconfig.dalsa)
    global dalsa dalsa_src;
    
    for(i=1:length(q.DeviceInfo))
        if(~isempty(strfind(q.DeviceInfo(i).DeviceName,'B2020M')))  %% search for imperx B2020M camera
            break;
        end
    end
    
    dalsa = videoinput('gige', i, 'Mono8');
    dalsa_src = getselectedsource(dalsa);
    dalsa_src.BinningHorizontal = 'x2';
    dalsa_src.BinningVertical = 'x2';
    dalsa_src.ReverseX = 'True';
    
    dalsa.FramesPerTrigger = inf;
    
    dalsa_src.ConstantFrameRate = 'True';
    dalsa_src.ExposureMode = 'Timed';
    dalsa_src.ExposureTimeRaw = dalsa_src.MaxExposure;
    dalsa_src.BinningHorizontal = 'x2';
    dalsa_src.BinningVertical = 'x2';
    
    dalsa_src.ReverseX = 'True';
    dalsa_src.ReverseY = 'False';
    
    dalsa_src.DigitalGainAll = 0;
    dalsa_src.DigitalOffsetAll = 512;
    
    % % This was for the Dalsa 1410
    % %
    %     for(i=1:length(q.DeviceInfo))
    %         if(~isempty(strfind(q.DeviceInfo(i).DeviceName,'1410')))
    %             break;
    %         end
    %     end
    %
    %     dalsa = videoinput('gige', i, 'Mono8');
    %     dalsa_src = getselectedsource(dalsa);
    %     dalsa_src.ReverseX = 'True';
    %     dalsa.FramesPerTrigger = inf;
    
end

set(sbt,'String','Configuring eyetracker'); drawnow;

% eye tracker...

if(sbconfig.eyetracker)
    
    global eyecam eye_src eye_roi;
    
    for(i=1:length(q.DeviceInfo)) % find camera...
        if(~isempty(strfind(q.DeviceInfo(i).DeviceName,'1280')))
            break;
        end
    end
    
    eyecam = videoinput('gige', i, 'Mono8');
    eye_src = getselectedsource(eyecam);
    eye_src.ReverseX = 'False';
    eye_src.BinningHorizontal = 2;
    eye_src.BinningVertical = 2;
    % eye_src.AcquisitionFrameRateAbs = 20;
    eye_src.AcquisitionFrameRateRaw = 15000;
    eye_src.ExposureTimeAbs = 7000;
    eyecam.FramesPerTrigger = inf;
    eyecam.ReturnedColorspace = 'grayscale';
    eye_roi = [0 0 eyecam.VideoResolution];
    
    
    % vid.TriggerRepeat = # frames to be collected...  or inf...
    % triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
    % src.FrameStartTriggerMode = 'On'
    % src.FrameStartTriggerSource = 'Line2'
    % vid.FramesPerTrigger = 1;
    
    % To go back...
    %     triggerconfig(vid, 'immediate', 'none', 'none');
    %     vid.FramesPerTrigger = inf;
    %     vid.TriggerRepeat = 1;
    %     src.FrameStartTriggerMode = 'Off'
    
end

% ttl boxes... Now removed because it took too much time...

% ttl0 = annotation('rectangle',[.214 .974 0.02 0.02],'EdgeColor',[0 0 0],'FaceColor',[0 0 0]);
% ttl1 = annotation('rectangle',[.214+0.022 .974 0.02 0.02],'EdgeColor',[0 0 0],'FaceColor',[0 0 0]);

set(sbt,'String','Setting up digitizer'); drawnow;

% dummy fig 1
figure(1);
set(1,'visible','off');

% Digitizer initialization

AlazarDefs;

% Load driver library
if ~alazarLoadLibrary()
    warndlg(sprintf('Error: ATSApi.dll not loaded\n'),'scanbox');
    return
end

systemId = int32(1);
boardId = int32(1);

global boardHandle

% Get a handle to the board
boardHandle = calllib('ATSApi', 'AlazarGetBoardBySystemID', systemId, boardId);
setdatatype(boardHandle, 'voidPtr', 1, 1);
if boardHandle.Value == 0
    warndlg(sprintf('Error: Unable to open board system ID %u board ID %u\n', systemId, boardId),'scanbox');
    return
end

% % Configure the board...
% %
% Set capture clock to external...

retCode = ...
    calllib('ATSApi', 'AlazarSetCaptureClock', ...
    boardHandle,		 ...	% HANDLE -- board handle
    FAST_EXTERNAL_CLOCK, ...	% U32 -- clock source id
    SAMPLE_RATE_USER_DEF, ...	% U32 -- IGNORED when clock is external!
    CLOCK_EDGE_RISING,	...	% U32 -- clock edge id
    0					...	% U32 -- clock decimation by 4 (3 is one less)
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarSetCaptureClock failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end


% % set external clock level if needed...
% % Not supported in 9440...!!!!

retCode = ...
    calllib('ATSApi', 'AlazarSetExternalClockLevel', ...
    boardHandle,		 ...	% HANDLE -- board handle
    single(65.0)	     ...	% U32 --level in percent
    );
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetExternalClockLevel failed -- %s\n', errorToText(retCode));
    return
end


% Set CHA input parameters

retCode = ...
    calllib('ATSApi', 'AlazarInputControl', ...
    boardHandle,		...	% HANDLE -- board handle
    CHANNEL_A,			...	% U8 -- input channel
    DC_COUPLING,		...	% U32 -- input coupling id
    INPUT_RANGE_PM_200_MV, ...	% U32 -- input range id
    IMPEDANCE_50_OHM	...	% U32 -- input impedance id
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarInputControl failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% CHB params...

retCode = ...
    calllib('ATSApi', 'AlazarInputControl', ...
    boardHandle,		...	% HANDLE -- board handle
    CHANNEL_B,			...	% U8 -- channel identifier
    DC_COUPLING,		...	% U32 -- input coupling id
    INPUT_RANGE_PM_200_MV,	...	% U32 -- input range id
    IMPEDANCE_50_OHM	...	% U32 -- input impedance id
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarInputControl failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end


% Select trigger inputs...

retCode = ...
    calllib('ATSApi', 'AlazarSetTriggerOperation', ...
    boardHandle,		...	% HANDLE -- board handle
    TRIG_ENGINE_OP_J,	...	% U32 -- trigger operation
    TRIG_ENGINE_J,		...	% U32 -- trigger engine id
    TRIG_EXTERNAL,		...	% U32 -- trigger with TRIGOUT
    TRIGGER_SLOPE_POSITIVE,	... % U32 -- THE HSYNC is flipped on the PSoC board...
    160,				...	% U32 -- trigger level from 0 (-range) to 255 (+range) DLR!!
    TRIG_ENGINE_K,		...	% U32 -- trigger engine id
    TRIG_DISABLE,		...	% U32 -- trigger source id for engine K
    TRIGGER_SLOPE_POSITIVE, ...	% U32 -- trigger slope id
    128					...	% U32 -- trigger level from 0 (-range) to 255 (+range)
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarSetTriggerOperation failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% External trigger params...
retCode = ...
    calllib('ATSApi', 'AlazarSetExternalTrigger', ...
    boardHandle,		...	% HANDLE -- board handle
    uint32(DC_COUPLING),		...	% U32 -- external trigger coupling id
    uint32(ETR_1V)				...	% U32 -- external trigger range id
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarSetExternalTrigger failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% Delays...

triggerDelay_samples = uint32(0);
retCode = calllib('ATSApi', 'AlazarSetTriggerDelay', boardHandle, triggerDelay_samples);
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarSetTriggerDelay failed -- %s\n', errorToText(retCode)),'scanbox');
    return;
end

% Trigger timeout...

retCode = ...
    calllib('ATSApi', 'AlazarSetTriggerTimeOut', ...
    boardHandle,            ...	% HANDLE -- board handle
    uint32(0)	... % U32 -- timeout_sec / 10.e-6 (0 == wait forever)
    );
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarSetTriggerTimeOut failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% Configure AUX I/O

% Config TTL as inputs into two LSBs of stream...

set(sbt,'String','Configuring TTLs'); drawnow;

configureLsb9440(boardHandle,2,3);   %% was 2,3

% update laser status

% set(handles.lstatus,'String',laser_status);

global ltimer;  % laser timer

if(~isempty(sbconfig.laser_type))
    ltimer = timer('ExecutionMode','FixedRate','Period',5,'TimerFcn',@laser_cb);
    start(ltimer);
end

if(sbconfig.qmotion==1)
    global qserial;
    qserial = serial(sbconfig.qmotion_com,'baud',38400,'terminator','','bytesavailablefcnmode','byte','bytesavailablefcncount',1,'bytesavailablefcn',@qmotion_cb);
    fopen(qserial);
end


% Done with daq configuration .... !!!!

set(sbt,'String','Done!'); drawnow;
pause(0.5);
close(h);


% UIWAIT makes scanbox wait for user response (see UIRESUME)
% uiwait(handles.scanboxfig);


% --- Outputs from this function are returned to the command line.
function varargout = scanbox_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in magnification.
function magnification_Callback(hObject, eventdata, handles)
% hObject    handle to magnification (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns magnification contents as cell array
%        contents{get(hObject,'Value')} returns selected item from magnification

sb_setmag(get(hObject,'Value')-1);
set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');

% WindowAPI(handles.scanboxfig,'setfocus')



% --- Executes during object creation, after setting all properties.
function magnification_CreateFcn(hObject, eventdata, handles)
% hObject    handle to magnification (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lines_Callback(hObject, eventdata, handles)
% hObject    handle to lines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lines as text
%        str2double(get(hObject,'String')) returns contents of lines as a double

global img0_h nlines sbconfig;

nlines = str2num(get(hObject,'String'));
if(isempty(nlines))
    nlines = 512;
    set(hObject,'String','512');
    warndlg('The number of lines must be a number! Resetting to default value (512).');
else
    sb_setline(nlines);
    frame_rate = sbconfig.resfreq/nlines; %% use actual resonant freq...
    set(handles.frate,'String',sprintf('%2.2f',frame_rate));
end


% --- Executes during object creation, after setting all properties.
function lines_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function frames_Callback(hObject, eventdata, handles)
% hObject    handle to frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frames as text
%        str2double(get(hObject,'String')) returns contents of frames as a double

n = str2num(get(hObject,'String'));
if(isempty(n))
    set(hObject,'String','0');
    warndlg('Total frames must be a number! Resetting to default value (0 = forever).');
    sb_setframe(0);
else
    sb_setframe(n);
end

% --- Executes during object creation, after setting all properties.
function frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in laserbutton.
function laserbutton_Callback(hObject, eventdata, handles)
% hObject    handle to laserbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of laserbutton

global sbconfig;


switch sbconfig.laser_type
    case 'CHAMELEON'
        laser_send(sprintf('LASER=%d',get(hObject,'Value')));
    case 'MAITAI'
        if(get(hObject,'Value'))
            r = laser_send('READ:PCTWARMEDUP?');
            if(~isempty(strfind(r,'100')))
                laser_send(sprintf('ON'));
            else
                set(hObject,'Value',0);
            end
        else
            laser_send(sprintf('OFF'));
        end
end

if(get(hObject,'Value'))
    set(hObject,'String','Laser is on','FontWeight','bold','Value',1);
else
    set(hObject,'String','Laser is off','FontWeight','normal','Value',0);
end



% --- Executes on button press in shutterbutton.
function shutterbutton_Callback(hObject, eventdata, handles)
% hObject    handle to shutterbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of shutterbutton

global sbconfig;

switch sbconfig.laser_type
    case 'CHAMELEON'
        laser_send(sprintf('SHUTTER=%d',get(hObject,'Value')));
    case 'MAITAI'
        laser_send(sprintf('SHUTTER %d',get(hObject,'Value')));
end

if(get(hObject,'Value'))
    set(hObject,'String','Shutter open','FontWeight','bold','Value',1);
else
    set(hObject,'String','Shutter closed','FontWeight','normal','Value',0);
end


function wavelength_Callback(hObject, eventdata, handles)
% hObject    handle to wavelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wavelength as text
%        str2double(get(hObject,'String')) returns contents of wavelength as a double

global sbconfig;

val = str2num(get(hObject,'String'));

if(isempty(val))
    set(hObject,'String','920');
    warndlg('Wavelength must a number! Resetting to 920nm');
elseif (val>1040 || val<700)
    set(hObject,'String','920');
    warndlg('Wavelength must a number between 700-1040nm.  Resetting to 920nm');
end

switch sbconfig.laser_type;
    case 'CHAMELEON'
        laser_send(sprintf('WAVELENGTH=%s',get(hObject,'String')));
        
    case 'MAITAI'
        laser_send(sprintf('WAVELENGTH %s',get(hObject,'String')));
end




% --- Executes during object creation, after setting all properties.
function wavelength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wavelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global wave_h;

wave_h = hObject;

%laser_send(sprintf('WAVELENGTH=%s',get(hObject,'String')));


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3

global mstep axis_sel

switch(get(hObject,'Value'))
    case 1
        v = [2000 380;   %z - max vel and acceleration
             2000 380;   %y
             2000 380;   %x
             2000 380];  %a
        mstep = [500 2000 2000 500];  % step size
        
    case 2
        v = [1200 300;
            1200 300;
            1200 300;
            1200 300];
        mstep = [50 200 200 50];
        
    case 3
        v = [650 200;
            650 200;
            650 200;
            650 200];
        mstep = [5 20 20 5];
end


for(i=0:3)
    r = tri_send('SAP',4,i,v(axis_sel+1,1));
    r = tri_send('SAP',5,i,v(axis_sel+1,2));
end

switch axis_sel
    case '2'
        set(handles.xpos,'ForegroundColor',[1 0 0]);
        set(handles.ypos,'ForegroundColor',[0 0 0]);
        set(handles.zpos,'ForegroundColor',[0 0 0]);
        set(handles.thpos,'ForegroundColor',[0 0 0]);
        axis_sel = 2; % x
    case '3'
        set(handles.xpos,'ForegroundColor',[0 0 0]);
        set(handles.ypos,'ForegroundColor',[1 0 0]);
        set(handles.zpos,'ForegroundColor',[0 0 0]);
        set(handles.thpos,'ForegroundColor',[0 0 0]);
        axis_sel = 1; % y
    case '4'
        set(handles.xpos,'ForegroundColor',[0 0 0]);
        set(handles.ypos,'ForegroundColor',[0 0 0]);
        set(handles.zpos,'ForegroundColor',[1 0 0]);
        set(handles.thpos,'ForegroundColor',[0 0 0]);
        axis_sel = 0; % z
    case '5'
        set(handles.xpos,'ForegroundColor',[0 0 0]);
        set(handles.ypos,'ForegroundColor',[0 0 0]);
        set(handles.zpos,'ForegroundColor',[0 0 0]);
        set(handles.thpos,'ForegroundColor',[1 0 0]);
        axis_sel = 3; % th
end

set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');




% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in motorlock.
function motorlock_Callback(hObject, eventdata, handles)
% hObject    handle to motorlock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of motorlock

% set(hObject,'enable','off');
% drawnow;
% set(hObject,'enable','on');
%WindowAPI(handles.scanboxfig,'setfocus')
% set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');



function xpos_Callback(hObject, eventdata, handles)
% hObject    handle to xpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xpos as text
%        str2double(get(hObject,'String')) returns contents of xpos as a double

eventdata.Character = 2;
scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function xpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function ypos_Callback(hObject, eventdata, handles)
% hObject    handle to ypos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ypos as text
%        str2double(get(hObject,'String')) returns contents of ypos as a double


% --- Executes during object creation, after setting all properties.
function ypos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ypos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function zpos_Callback(hObject, eventdata, handles)
% hObject    handle to zpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zpos as text
%        str2double(get(hObject,'String')) returns contents of zpos as a double


% --- Executes during object creation, after setting all properties.
function zpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function thpos_Callback(hObject, eventdata, handles)
% hObject    handle to thpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thpos as text
%        str2double(get(hObject,'String')) returns contents of thpos as a double


% --- Executes during object creation, after setting all properties.
function thpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton16.
function pushbutton16_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global datadir

datadir = uigetdir('Data directory');
set(handles.dirname,'String',datadir);


% --- Executes on button press in grabb.
function grabb_Callback(hObject, eventdata, handles)
% hObject    handle to grabb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


global animal experiment trial savesel seg img0_h captureDone;
global scanbox_h buffersPerAcquisition;
global pmtdisp_h;

% do some basic checking...

global wcam eyecam sbconfig;



wf=0;
swrn = 'Fix the following before imaging:';

if(~isempty(sbconfig.laser_type))
    
    if(get(handles.laserbutton,'Value')==0)
        wf = wf + 1;
        swrn = sprintf('%s\n%s',swrn,'Turn the laser on and wait for modelock');
    end
    
    if(get(handles.shutterbutton,'Value')==0)
        wf = wf + 1;
        swrn = sprintf('%s\n%s',swrn,'Open the laser shutter');
    end
    
end

if(get(handles.camerabox,'Value')==1)
    wf = wf + 1;
    swrn = sprintf('%s\n%s',swrn,'Camara pathway is activated.');
end

if(get(handles.pmtenable,'Value')==0)
    wf = wf + 1;
    swrn = sprintf('%s\n%s',swrn,'Turn PMTs on and set their gains.');
end

global z_vals;

if(wf>0)
    warndlg(swrn);
    return;
end


% turn zoom off

zoom(scanbox_h,'off');
pan(scanbox_h,'off');

AlazarDefs; % board constants

global shutter_h histbox_h;

global boardHandle saveData fid stim_on buffersCompleted messages;

global ttl0 ttl1;

global abort_bit;

stim_on = 0;

switch(get(hObject,'String'))
    case 'Focus'
        abort_bit = 0;
        set(hObject,'String','Abort');
        set(handles.grabb,'Enable','off'); % make this invisible
        frames = 0;
        saveData = false;                % if data are being saved or not...
        set(messages,'String',{});  % clear messages...
        set(messages,'ListBoxTop',1);
        set(messages,'Value',1);
        drawnow;
    case 'Grab'
        abort_bit = 0;
        set(hObject,'String','Abort');
        set(handles.focusb,'Enable','off'); % make this invisible
        frames = str2num(get(handles.frames,'String'));
        saveData = true;                % if data are being saved or not...
        set(messages,'String',{});  % clear messages...
        set(messages,'ListBoxTop',1);
        set(messages,'Value',1);
        drawnow;
    case 'Abort'
        abort_bit = 1;
        sb_abort;
        retCode = calllib('ATSApi', 'AlazarAbortAsyncRead', boardHandle);
        if retCode ~= ApiSuccess
            warndlg(sprintf('Error: AlazarAbortCapture failed-- %s\n', errorToText(retCode)),'scanbox');
        end
        set(handles.grabb,'String','Grab','Enable','on'); % make this invisible
        set(handles.focusb,'String','Focus','Enable','on'); % make this invisible
        captureDone = 1;
        %         if(saveData && (fid>0))
        %             fclose(fid);
        %         end
        %         drawnow;
        return;
end


if frames==0
    frames = hex2dec('7fffffff'); % Inf for Alazar card
end

% set lines/mag/frames

lines  = str2num(get(handles.lines,'String'));
mag = get(handles.magnification,'Value')-1;
sb_setparam(lines,frames,mag);

recordsPerBuffer = lines;       % this is HALF the number of lines...  line_max/2
buffersPerAcquisition = frames; % Total  number of frames to capture

% Capture both channels
channelMask = CHANNEL_A + CHANNEL_B;

% Buffer time out....
bufferTimeout_ms = 2000;

% No of channels to sample
channelCount = 2;

% Get the sample and memory size
[retCode, boardHandle, maxSamplesPerRecord, bitsPerSample] = calllib('ATSApi', 'AlazarGetChannelInfo', boardHandle, 0, 0);
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarGetChannelInfo failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% Calculate sizes

postTriggerSamples = 5000;              % just one line...
samplesPerRecord =   postTriggerSamples;  % 10000/4 (1 sample every laser clock) samples per scan (back and forth)
bytesPerSample = 2;

samplesPerBuffer = samplesPerRecord * recordsPerBuffer * channelCount ;
bytesPerBuffer   = samplesPerBuffer * bytesPerSample;

% Prepare DMA buffers...

global sbconfig;

bufferCount = uint32(sbconfig.nbuffer); % Pre allocate buffers to store the data...

buffers = cell(1,bufferCount);
for j = 1 : bufferCount
    buffers{j} = libpointer('uint16Ptr', 1:samplesPerBuffer) ;
end

% Create a data file if required

fid = -1;
if saveData
    global datadir animal experiment unit
    
    fn = [datadir filesep animal filesep sprintf('%s_%03d',animal,unit) '_'  sprintf('%03d',experiment) '.sbx'];
    if(exist(fn,'file'))
        warndlg('Data file exists!  Cannot overwrite! Aborting...');
        set(handles.grabb,'String','Grab','Enable','on'); % make this invisible
        set(handles.focusb,'String','Focus','Enable','on'); % make this invisible
        abort_bit = 1;
        return;
    end
    
    fid = fopen(fn,'w');
    if fid == -1
        warndlg(sprintf('Error: Unable to create data file\n'),'scanbox');
        return;
    end
end

% Set the record size
retCode = calllib('ATSApi', 'AlazarSetRecordSize', boardHandle, uint32(0), uint32(postTriggerSamples));
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarBeforeAsyncRead failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% TODO: Select AutoDMA flags as required
% ADMA_NPT - Acquire multiple records with no-pretrigger samples
% ADMA_EXTERNAL_STARTCAPTURE - call AlazarStartCapture to begin the acquisition
% ADMA_INTERLEAVE_SAMPLES - interleave samples for highest throughput

admaFlags = ADMA_EXTERNAL_STARTCAPTURE + ADMA_NPT + ADMA_INTERLEAVE_SAMPLES;

% Configure the board to make an AutoDMA acquisition
recordsPerAcquisition = recordsPerBuffer * buffersPerAcquisition;
retCode = calllib('ATSApi', 'AlazarBeforeAsyncRead', boardHandle, uint32(channelMask), uint64(0), uint32(samplesPerRecord), uint32(recordsPerBuffer),uint32(recordsPerAcquisition), uint32(admaFlags));
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarBeforeAsyncRead failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% Post the buffers to the board
for bufferIndex = 1 : bufferCount
    pbuffer = buffers{bufferIndex};
    retCode = calllib('ATSApi', 'AlazarPostAsyncBuffer', boardHandle, pbuffer, uint32(bytesPerBuffer));
    if retCode ~= ApiSuccess
        warndlg(sprintf('Error: AlazarPostAsyncBuffer failed -- %s\n', errorToText(retCode)),'scanbox');
        sb_abort;
        return
    end
end

% Arm the board system to wait for triggers
retCode = calllib('ATSApi', 'AlazarStartCapture', boardHandle);
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarStartCapture failed -- %s\n', errorToText(retCode)),'scanbox');
    return
end

% Prepare image axis

global chA acc tfilter_h  scanbox_h img0_h img0_axis;

%set(get(img0_h,'Parent'),'xlim',[0 samplesPerRecord/4-1],'ylim',[0 recordsPerBuffer-1]);

if(get(handles.camerabox,'Value')==0)
    set(get(img0_h,'Parent'),'xlim',[0 796-1],'ylim',[0 recordsPerBuffer-1]);
    set(img0_h,'CData',255*ones([512 796],'uint8'));
    set(img0_h,'erasemode','none');
    axis off;
end

% loop vars...

buffersCompleted = 0;
captureDone = false;
success = false;
acc=[];
nacc=0;
trial_acc={};
trial_n=[];
ttlflag = 0;

global sb_server sb sbconfig;

set(sb_server,'BytesAvailableFcn','');  % what's this?

global wcam wcam_src eyecam eye_src ballpos ballarrow ballmotion;
global datadir experiment animal unit;
global wcamlog eyecamlog;
global wcam_roi eye_roi;
global sbconfig;
global ttlonline;


% if(get(handles.wc,'Value'))
%     set(wcam,'LoggingMode','memory');
%     fn = sprintf('%s\\%s\\%s_%03d_%03d_ball.avi',datadir,animal,animal,unit,experiment);
%     wcamlog = VideoWriter(fn,'Motion JPEG AVI');
%     wcam.DiskLogger = wcamlog;
%     ballmotion = [];
% else
%     set(wcam,'LoggingMode','memory');
% end
%
% if(get(handles.eyet,'Value'))           % Are we tracking the eyes/pupil?
%     set(eyecam,'LoggingMode','memory');
%     fn = sprintf('%s\\%s\\%s_%03d_%03d_eye.avi',datadir,animal,animal,unit,experiment);
%     eyecamlog = VideoWriter(fn,'Motion JPEG AVI');
%     eyecam.DiskLogger = eyecamlog;
% else
%     set(eyecam,'LoggingMode','memory');
% end


% start cameras at the same time as scanning... only if we are going to be
% saving a file...

if fid ~= -1
    if(get(handles.wc,'Value'))
        
        triggerconfig(wcam, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
        wcam.TriggerRepeat = inf;
        %wcam_src.FrameStartTriggerSource = 'Line2';
        wcam.FramesPerTrigger = 1;
        wcam_src.FrameStartTriggerMode = 'On';
        wcam.ROIPosition = wcam_roi;
        start(wcam);
        
    end
    
    if(get(handles.eyet,'Value'))
        
        triggerconfig(eyecam, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
        eyecam.TriggerRepeat = inf;
        %        eye_src.FrameStartTriggerSource = 'Line2';
        eyecam.FramesPerTrigger = 1;
        eye_src.FrameStartTriggerMode = 'On';
        eyecam.ROIPosition = eye_roi;
        
        start(eyecam);
    end
end


global ltimer;

if(~isempty(sbconfig.laser_type))
    stop(ltimer);
end

sb_scan;   % start scanning!

%set(handles.scanboxfig,'enable','off'); drawnow; set(handles.scanboxfig,'enable','on');
%WindowAPI(handles.scanboxfig,'setfocus');

%S = sparseint;

S = pixel_lut;
f_lap = fspecial('laplacian',.5);   % for ball tracking...

tic;

while ~captureDone
    
    sb_callback; % take care of USB events
    
    bufferIndex = mod(buffersCompleted, bufferCount) + 1;
    pbuffer = buffers{bufferIndex};
    
    % Wait for the first available buffer to be filled by the board
    [retCode, boardHandle, bufferOut] = ...
        calllib('ATSApi', 'AlazarWaitAsyncBufferComplete', boardHandle, pbuffer, uint32(bufferTimeout_ms));
    if retCode == ApiSuccess
        % This buffer is full
        bufferFull = true;
        captureDone = false;
    elseif retCode == ApiWaitTimeout
        % The wait timeout expired before this buffer was filled.
        % The board may not be triggering, or the timeout period may be too short.
        
        warndlg(sprintf('Warning: AlazarWaitAsyncBufferComplete timeout -- Verify trigger!\n'),'scanbox');
        
        bufferFull = false;
        captureDone = true;
    else
        % The acquisition failed
        warndlg(sprintf('Error: AlazarWaitAsyncBufferComplete failed -- %s\n', errorToText(retCode)),'scanbox');
        bufferFull = false;
        captureDone = true;
    end
    
    if bufferFull
        
        setdatatype(bufferOut, 'uint16Ptr', 1, samplesPerBuffer);  %% keep bytes separate
        
        % Save the buffer to file
        
        if fid ~= -1
            switch(savesel)
                case 1
                    fwrite(fid, bufferOut.Value,'uint16');
                case 2
                    tmp = reshape(bufferOut.Value,[2 length(bufferOut.Value)/2]);
                    fwrite(fid, tmp(1,:),'uint16');
                case 3
                    tmp = reshape(bufferOut.Value,[2 length(bufferOut.Value)/2]);
                    fwrite(fid, tmp(2,:),'uint16');
            end
        end
        
        % draw image
        
        switch(get(pmtdisp_h,'Value'))
            
            case 1    % PMT0
                
                chA = reshape(bufferOut.Value,[2 4 1250 recordsPerBuffer]);
                
                %                 ttl0s = any(bitand(chA(:),uint16(1)));
                %                 ttl1s = any(bitand(chA(:),uint16(2)));
                
                %                 ttl = bitand(squeeze(chA(1,1,1,end)),uint16(3));
                %                 chA = squeeze(mean(chA(1,:,:,:),2))' /256;
                %                 chA = uint8(chA*S);
                
                % Faster code replaces the above...
                
                chA = squeeze(uint8(bitshift(chA(1,1,S,:),-8)))';
                
                
            case 2    % PMT1
                
                chA = reshape(bufferOut.Value,[2 4 1250 recordsPerBuffer]);
                
                %                 ttl0s = any(bitand(chA(:),uint16(1)));
                %                 ttl1s = any(bitand(chA(:),uint16(2)));
                
                %                 ttl = bitand(squeeze(chA(1,1,1,end)),uint16(3));
                %                 chA = squeeze(mean(chA(2,:,:,:),2))' /256;
                %                 chA = uint8(chA*S);
                
                chA = squeeze(uint8(bitshift(chA(2,1,S,:),-8)))';
                
            case 3 % MERGED
                
                chA = reshape(bufferOut.Value,[2 4 1250 recordsPerBuffer]);
                
                %                 ttl0s = any(bitand(chA(:),uint16(1)));
                %                 ttl1s = any(bitand(chA(:),uint16(2)));
                
                
                %                 chA = squeeze(mean(chA,2))/256;
                %                 chAf = squeeze(chA(1,:,:))' * S;
                %                 chBf = squeeze(chA(2,:,:))' * S;
                %                 %chA = imfuse(chAf,chBf);
                
                chAf = squeeze(uint8(bitshift(chA(1,1,S,:),-8)))';
                chBf = squeeze(uint8(bitshift(chA(2,1,S,:),-8)))';
                
                chA = zeros([size(chAf) 3],'uint8');
                chA(:,:,2) = 255-chAf;
                chA(:,:,1) = 255-chBf;
                
            case 4 %SIDE BY SIDE
                
                chA = reshape(bufferOut.Value,[2 4 1250 recordsPerBuffer]);
                
                %                 ttl0s = any(bitand(chA(:),uint16(1)));
                %                 ttl1s = any(bitand(chA(:),uint16(2)));
                
                %                 chA = floor(squeeze(mean(chA,2))/512);
                %                 chAf = uint8(squeeze(chA(1,:,:))' * S);
                %                 chBf = uint8(squeeze(chA(2,:,:))' * S);
                
                chAf = squeeze(uint8(bitshift(chA(1,1,S,:),-8)))';
                chBf = squeeze(uint8(bitshift(chA(2,1,S,:),-8)))';
                
                chA = [chAf (128+chBf)] ;
                chA = chA(1:2:end,1:2:end);
                chA = [255*ones([size(chA,1)/2 size(chA,2)],'uint8'); chA ; 255*ones([size(chA,1)/2 size(chA,2)],'uint8')];
        end
        
        
        if(get(handles.camerabox,'Value')==0)
            switch get(tfilter_h,'Value')
                
                case 1
                    set(img0_h,'Cdata',chA);
                case 2
                    
                    if(isempty(acc))
                        acc = uint8(chA);
                    else
                        acc = min(acc,chA);
                    end
                    set(img0_h,'Cdata',chA);
                    
                case 3                          %% accumulate and keep value in global var acc
                    if(isempty(acc))
                        acc = zeros(size(chA),'uint32');
                        acc = uint32(chA);
                        nacc = 1;
                    else
                        acc = acc + uint32(chA);
                        nacc = nacc+1;
                    end
                    set(img0_h,'Cdata',chA);
            end
        end
        
        
        if(fid~=-1 && ttlonline)
            switch(ttlflag)
                case 0
                    if(bitand(bufferOut.Value(1),uint16(3)))
                        set(handles.ttlonline,'ForegroundColor',[1 0 0]);
                        ttlflag = 1;
                        if(~isempty(acc))
                            acc = [];
                            nacc = 0;
                        end
                    end
                    
                case 1
                    if(bitand(bufferOut.Value(1),uint16(3))==0)
                        set(handles.ttlonline,'ForegroundColor',[0 0 0]);
                        if(~isempty(acc))
                            trial_acc{end+1} = acc;
                            trial_n(end+1) = nacc;
                            acc = [];
                            nacc = 0;
                        end
                        ttlflag = 0;
                    end
            end
        end
        
        
        % ttls
        
        %         if(ttl0s)
        %             set(ttl0,'FaceColor',[0 1 0]);
        %         else
        %             set(ttl0,'FaceColor',[0 0 0]);
        %         end
        %
        %         if(ttl1s)
        %             set(ttl1,'FaceColor',[0 1 0]);
        %         else
        %             set(ttl1,'FaceColor',[0 0 0]);
        %         end
        
        drawnow ;   % damn important!!! to dispatch abort commands...
        
        % Make the buffer available to be filled again by the board
        retCode = calllib('ATSApi', 'AlazarPostAsyncBuffer', boardHandle, pbuffer, uint32(bytesPerBuffer));
        if retCode ~= ApiSuccess
            if(retCode ~= 520)
                warndlg(sprintf('Error: AlazarPostAsyncBuffer failed -- %s\n', errorToText(retCode)),'scanbox');
            end
            captureDone = true;
        end
        
        % Update progress
        
        buffersCompleted = buffersCompleted + 1;
        
        if buffersCompleted >= buffersPerAcquisition;
            captureDone = true;
            success = true;
        end
        
    end % if bufferFull
    
    if (sb_server.BytesAvailable>0)
        udp_cb(sb_server,[]);
    end
    
    % update counter/timer
    
    set(handles.etime,'String',sprintf('%06d -- %s',buffersCompleted, datestr(datenum(0,0,0,0,0,toc),'HH:MM:SS')));
    
    % Are we tracking the ball?
    
    % We are now streaming to disk...
    
    %     if(get(handles.wc,'Value'))
    %         if(wcam.FramesAvailable>2)
    %             wcdata = getdata(wcam,wcam.FramesAvailable);
    %             global z1;
    %             z1 = squeeze(wcdata(:,:,end-1));
    %             z2 = squeeze(wcdata(:,:,end-2));
    %             z1 = filter2(f_lap,z1,'valid');
    %             z2 = filter2(f_lap,z2,'valid');
    %             c=fftshift(real(ifft2(fft2(z1).*fft2(rot90(z2,2)))));
    %             idx = find(max(c(:))==c);
    %             [imax,jmax] = ind2sub(size(z1),idx);
    %
    %             set(ballarrow,'X',[ballpos(1) ballpos(1)+(jmax-size(z1,2)/2)/400] ,'Y' ,[ballpos(2) ballpos(2)+(imax-size(z1,1)/2)/400]);
    %             ballmotion(buffersCompleted,:) = [(jmax-size(z1,2)/2) (imax-size(z1,1)/2)];
    %         else
    %             ballmotion(buffersCompleted,:) = [NaN NaN];
    %         end
    %     end
    
end % while ~captureDone

%
if ~isempty(acc)
    accd =  double(acc);
    accd = ((accd-min(accd(:)))/(max(accd(:))-min(accd(:))));
    set(img0_h,'Cdata',uint8(255*accd));
end

% set(ttl0,'FaceColor',[0 0 0]);  % reset TTL signal viewer
% set(ttl1,'FaceColor',[0 0 0]);

set(handles.ttlonline,'ForegroundColor',[0 0 0]);
if(fid ~= -1)
    if(ttlonline && ~isempty(trial_acc))
        fn = sprintf('%s\\%s\\%s_%03d_%03d_trials.mat',datadir,animal,animal,unit,experiment);
        oldstr = get(handles.etime,'String');
        set(handles.etime,'String','Saving trial data...','ForegroundColor',[1 0 0]);
        drawnow;
        save(fn,'trial_acc','trial_n');
        clear trial_acc trial_n;
        set(handles.etime,'String',oldstr,'ForegroundColor',[0 0 0]);
    end
end

if(fid ~= -1)
    
    if(get(handles.wc,'Value'))
        stop(wcam); % stop web cam...
        triggerconfig(wcam, 'immediate', 'none', 'none');
        wcam.FramesPerTrigger = inf;
        wcam.TriggerRepeat = 1;
        wcam_src.FrameStartTriggerMode = 'Off';
        wcam.ROIPosition = wcam_roi;
    end
    
    if(get(handles.eyet,'Value'))
        stop(eyecam); % stop eye cam...
        triggerconfig(eyecam, 'immediate', 'none', 'none');
        eyecam.FramesPerTrigger = inf;
        eyecam.TriggerRepeat = 1;
        eye_src.FrameStartTriggerMode = 'Off';
        eyecam.ROIPosition = eye_roi;
    end
    
    if(get(handles.wc,'Value') || get(handles.eyet,'Value'))
        oldstr = get(handles.etime,'String');
        set(handles.etime,'String','Saving tracking data...','ForegroundColor',[1 0 0]);
        drawnow;
        
        if(get(handles.wc,'Value')) % write wcam data...
            [data,time,abstime] = getdata(wcam);
            fn = sprintf('%s\\%s\\%s_%03d_%03d_ball.mat',datadir,animal,animal,unit,experiment);
            flushdata(wcam);
            
            save(fn,'data','time','abstime');
            clear data time abstime;
        end
        
        if(get(handles.eyet,'Value')) % write eyet data...
            [data,time,abstime] = getdata(eyecam);
            fn = sprintf('%s\\%s\\%s_%03d_%03d_eye.mat',datadir,animal,animal,unit,experiment);
            flushdata(eyecam);
            save(fn,'data','time','abstime');
            clear data time abstime;
        end
        
        set(handles.etime,'String',oldstr,'ForegroundColor',[0 0 0]);
    end
end


% if(sb_server.BytesAvailable>0)
%     fread(sb_server,sb_server.BytesAvailable); % discard whatever was there...
% end

% udp_cb;
%

sb_server.BytesAvailableFcn = @udp_cb;  % restore...

% Stop scanner just in case...
sb_abort;
global ltimer;
if(~isempty(sbconfig.laser_type))
    start(ltimer);
end

% Terminate the acquisition
retCode = calllib('ATSApi', 'AlazarAbortAsyncRead', boardHandle);
if retCode ~= ApiSuccess
    warndlg(sprintf('Error: AlazarAbortAsyncRead failed -- %s\n', errorToText(retCode)),'scanbox');
end

% Restore buttons
set(handles.grabb,'String','Grab','Enable','on'); % make this invisible
set(handles.focusb,'String','Focus','Enable','on'); % make this invisible

% Release the buffers
for bufferIndex = 1:bufferCount
    clear buffers{bufferIndex};
end


%WindowAPI(handles.scanboxfig,'setfocus');

sb_callback; % any time stamps left?

% Close the data file
if fid ~= -1
    fclose(fid);
    fid = -1;
    fn = [datadir filesep animal filesep sprintf('%s_%03d',animal,unit) '_'  sprintf('%03d',experiment) '.mat'];
    info = sb_timestamps;   % get time stamps and image size...
    info.resfreq = sbconfig.resfreq;    % resonant frequency in Hz...
    info.postTriggerSamples = postTriggerSamples;
    info.recordsPerBuffer = recordsPerBuffer;
    info.bytesPerBuffer = bytesPerBuffer;
    info.channels = get(handles.savesel,'Value');
    info.ballmotion = ballmotion;
    info.abort_bit = abort_bit;
    info.config = scanbox_getconfig;
    
    % save any messages too...
    
    global messages;
    
    info.messages = get(messages,'String');
    
    set(messages,'String',{});  % clear messages after saving...
    set(messages,'ListBoxTop',1);
    set(messages,'Value',1);
    
    save(fn,'info');
end

function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in checkbox7.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7


% --- Executes on key press with focus on scanboxfig and none of its controls.
function scanboxfig_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to scanboxfig (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in zerobutton.
function zerobutton_Callback(hObject, eventdata, handles)
% hObject    handle to zerobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global origin dmpos

for(i=0:3)
    r = tri_send('GAP',0,i,0);
    origin(i+1) = r.value;
end

dmpos = origin;

set(handles.xpos,'String','0.00');
set(handles.ypos,'String','0.00');
set(handles.zpos,'String','0.00');
set(handles.thpos,'String','0.00');


%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
%WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes on button press in originbutton.
function originbutton_Callback(hObject, eventdata, handles)
% hObject    handle to originbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


global origin dmpos

% for(i=0:3)
%     r = tri_send('MVP',0,i,origin(i+1));
%     pause(0.25);
% end

for(i=0:2)
    r = tri_send('SCO',0,i,origin(i+1));
end

v = zeros(3,2);

for(i=0:2)                      % current vel and acc
    r1 = tri_send('GAP',4,i,0);
    r2 = tri_send('GAP',5,i,0);
    v(i+1,1) = r1.value;
    v(i+1,2) = r2.value;
    tri_send('SAP',4,i,1200);
    tri_send('SAP',5,i,275);
end

tri_send('MVP',2,hex2dec('87'),0);

set(hObject,'ForegroundColor',[1 0 0]);
drawnow;
st = 0;                         % wait for movement to finish
while(st==0)
    st = 1;
    for(i=0:2)
        r = tri_send('GAP',8,i,0);
        st = st * r.value;
    end
end
set(hObject,'ForegroundColor',[0 0 0]);
drawnow;

for(i=0:2)
    r1 = tri_send('SAP',4,i,v(i+1,1));
    r2 = tri_send('SAP',5,i,v(i+1,2));
end
                        
dmpos(1:3) = origin(1:3);
update_pos;

% set(handles.xpos,'String','0.00')
% set(handles.ypos,'String','0.00')
% set(handles.zpos,'String','0.00')
% set(handles.thpos,'String','0.00')



%set(hObject,'enable','off');drawnow; set(hObject,'enable','on');
%WindowAPI(handles.scanboxfig,'setfocus')



% --- Executes on selection change in pmtdisp.
function pmtdisp_Callback(hObject, eventdata, handles)
% hObject    handle to pmtdisp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pmtdisp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pmtdisp

% reset accumulator automatically...

global acc img0_h;

acc = [];
set(img0_h,'CData',255*ones([512 796],'uint8'));

switch(get(hObject,'Value'))
    case 1
        set(handles.low1,'Enable','off');
        set(handles.high1,'Enable','off');
        set(handles.gamma1,'Enable','off');
        
        set(handles.low,'Enable','on');
        set(handles.high,'Enable','on');
        set(handles.gamma,'Enable','on');
        
        low = get(handles.low,'Value');
        high = get(handles.high,'Value');
        gamma = get(handles.gamma,'Value');
        
        gencm(low,high,gamma);
        
        
    case 2
        set(handles.low1,'Enable','on');
        set(handles.high1,'Enable','on');
        set(handles.gamma1,'Enable','on');
        
        set(handles.low,'Enable','off');
        set(handles.high,'Enable','off');
        set(handles.gamma,'Enable','off');
        
        low = get(handles.low1,'Value');
        high = get(handles.high1,'Value');
        gamma = get(handles.gamma1,'Value');
        
        gencm(low,high,gamma);
        
        
    case 3
        set(handles.low1,'Enable','off');
        set(handles.high1,'Enable','off');
        set(handles.gamma1,'Enable','off');
        
        set(handles.low,'Enable','off');
        set(handles.high,'Enable','off');
        set(handles.gamma,'Enable','off');
        
    case 4
        set(handles.low1,'Enable','on');
        set(handles.high1,'Enable','on');
        set(handles.gamma1,'Enable','on');
        
        set(handles.low,'Enable','on');
        set(handles.high,'Enable','on');
        set(handles.gamma,'Enable','on');
        
        % generate combined colormap
        
        low = get(handles.low,'Value');
        high = get(handles.high,'Value');
        gamma = get(handles.gamma,'Value');
        
        gencm(low,high,gamma);
        
        low = get(handles.low1,'Value');
        high = get(handles.high1,'Value');
        gamma = get(handles.gamma1,'Value');
        
        appendcm(low,high,gamma);
        
end



% --- Executes during object creation, after setting all properties.
function pmtdisp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmtdisp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global pmtdisp_h;

pmtdisp_h = hObject;

% --- Executes during object creation, after setting all properties.
function image0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to image0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate image0

global img0_h img0_axis cm;

% colormaps

global cm;

cm = gray(256);
cm(end,:) = [1 0 0]; % saturation signal
cm = flipud(cm);
colormap(cm);

img0_h = imshow(ones(512,796,'uint8'),cm);
axis off image
%%%drawnow;

% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function pix_histo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pix_histo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate pix_histo

global histo_h;

histo_h = hObject;

% % --- Executes on button press in camerabox.
function camerabox_Callback(hObject, eventdata, handles)
% hObject    handle to camerabox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of camerabox

global vid img0_h cm dalsa sbconfig dalsa_src;

sb_mirror(get(hObject,'Value')-1);

if(sbconfig.dalsa==1)
    
    if(get(hObject,'Value'))
        %set(get(img0_h,'Parent'),'xlim',[0 679],'ylim',[0 511]);
        set(get(img0_h,'Parent'),'xlim',[0 dalsa_src.CUR_HRZ_SZE-1],'ylim',[0 dalsa_src.CUR_VER_SZE-1]);
        preview(dalsa,img0_h);
        %         set(handles.dalsa_panel,'visible','on');
        %         set(handles.dalsa_gain,'visible','on');
        % %         set(handles.cmap_panel,'visible','off');
        %         drawnow;
        
        %         set(handles.dalsa_gain,'Value',dalsa_src.GainRaw);
        %         set(handles.dalsa_exposure,'Value',dalsa_src.ExposureTimeAbs);
        
        set(handles.dalsa_gain,'Value',dalsa_src.DigitalGainAll);
        set(handles.dalsa_exposure,'Value',double(dalsa_src.ExposureTimeRaw) / double(dalsa_src.MaxExposure));
        
    else
        closepreview(dalsa);
        set(get(img0_h,'Parent'),'xlim',[0 795],'ylim',[0 511]);
        pmtdisp_Callback(handles.pmtdisp, [], handles);  % restore colormap...
        %         set(handles.dalsa_panel,'visible','off');
        %         set(handles.cmap_panel,'visible','on');
        %         drawnow;
    end
    
end


%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
%WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes during object creation, after setting all properties.
function shutterbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to shutterbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global shutter_h;

shutter_h = hObject;

% laser_send(sprintf('SHUTTER=%d',get(hObject,'Value')));



% --- Executes when user attempts to close scanboxfig.
function scanboxfig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to scanboxfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

global scanbox_h ltimer;

[~, ~] = system('netsh interface set interface "Local Area Connection" ENABLED');

delete(ltimer);

delete(hObject);

sb_gain1(0); % make sure pmt gains are zero
sb_gain0(0);

sb_close();
tri_close();
laser_close();
udp_close();
ot_start(); % reset to zero...
ot_close();

unloadlibrary('ATSApi')
clear all;      % clear all vars just in case...

% --- Executes during object creation, after setting all properties.
function scanboxfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanboxfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global scanbox_h seg;

scanbox_h = hObject;
seg = [];

% --- Executes on button press in timebin.
function timebin_Callback(hObject, eventdata, handles)
% hObject    handle to timebin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of timebin


% --- Executes on selection change in tfilter.
function tfilter_Callback(hObject, eventdata, handles)
% hObject    handle to tfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tfilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tfilter


% --- Executes during object creation, after setting all properties.
function tfilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global tfilter_h;

tfilter_h = hObject;


% --- Executes on button press in pix_histo.
function histbox_Callback(hObject, eventdata, handles)
% hObject    handle to pix_histo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pix_histo


% --- Executes during object creation, after setting all properties.
function histbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pix_histo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global histbox_h;

histbox_h = hObject;


% --- Executes during object deletion, before destroying properties.
function scanboxfig_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to scanboxfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in sfilter.
function sfilter_Callback(hObject, eventdata, handles)
% hObject    handle to sfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sfilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sfilter


% --- Executes during object creation, after setting all properties.
function sfilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in text14.
function text14_Callback(hObject, eventdata, handles)
% hObject    handle to text14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h;

zoom(scanbox_h,'off');      % make sure the zoom is off...
pan(scanbox_h,'off');
eventdata.Character = '@';
scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);

%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
% WindowAPI(handles.scanboxfig,'setfocus')



% --- Executes on button press in text15.
function text15_Callback(hObject, eventdata, handles)
% hObject    handle to text15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h;

zoom(scanbox_h,'off');      % make sure the zoom is off...
pan(scanbox_h,'off');
eventdata.Character = '#';
scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);
%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
% WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes on button press in text16.
function text16_Callback(hObject, eventdata, handles)
% hObject    handle to text16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h;

zoom(scanbox_h,'off');      % make sure the zoom is off...
pan(scanbox_h,'off');
eventdata.Character = '$';
scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);

%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
% WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes on button press in text17.
function text17_Callback(hObject, eventdata, handles)
% hObject    handle to text17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h;

zoom(scanbox_h,'off');      % make sure the zoom is off...
pan(scanbox_h,'off');
eventdata.Character = '%';
scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);
%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
% WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes on button press in focusb.
function focusb_Callback(hObject, eventdata, handles)
% hObject    handle to focusb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


grabb_Callback(hObject, eventdata, handles); % Call the grab button... with my own info


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton24.
function pushbutton24_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global acc;
acc = [];

%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');


% --- Executes on button press in pushbutton25.
function pushbutton25_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img0_h img0_axis p1 p2 seg scanbox_h;

N = 25; % size of cell neighborhood....

z = get(img0_h,'Cdata');  % keep original image

if(isempty(seg))
    seg.ncell = 0;
    seg.boundary = {};
    seg.pixels = {};
    seg.img = zeros(size(z)); % segmentation image
    i = 1;
else
    i = seg.ncell + 1;  % append cells...
end


axis(img0_axis);
x=round(ginput_c(1));
while(~isempty(x))
    hold on;
    plot(x(1),x(2),'r.','Tag','ctr','markersize',15);
    q = z((x(2)-N):(x(2)+N),(x(1)-N):(x(1)+N));
    m = cellseg(-double(q),p1,p2);
    if(~sum(m.mask(:))==0)
        seg.img((x(2)-N+1):(x(2)+N-1),(x(1)-N+1):(x(1)+N)-1) = m.mask*i;
        seg.pixels{i} = find(seg.img == i);
        i = i+1;
    end
    x = round(ginput_c(1));
end
hold off;
set(scanbox_h,'pointer','arrow');


seg.ncell = (i-1);

% delete centers and draw boundaries...

%  h = get(get(img0_h,'Parent'),'Children');
%  delete(h(1:end-1));

%%%drawnow;

h = get(get(img0_h,'Parent'),'Children');
delete(findobj(h,'tag','ctr'));

axis(img0_axis);
hold on;
for(i=1:seg.ncell)
    B{i} = bwboundaries(seg.img==i);
    b = B{i};
    for(j=1:length(b))
        bb = b{j};
        plot(bb(:,2),bb(:,1),'-','tag','bound','UserData',i,'color',[1 0.7 0]);
    end
end

if(seg.ncell>0)
    seg.boundary = B;
    cstr = {};
    m=1;
    for(k=1:seg.ncell)
        if(~isempty(seg.boundary{k}))
            cstr{m} = num2str(k);
            m = m+1;
        end
    end
    set(handles.cell_a,'String',cstr,'Value',1);
else
    set(handles.cell_a,'String','','Value',1);
end

set(handles.cell_d,'String','','Value',1);




function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit17 as text
%        str2double(get(hObject,'String')) returns contents of edit17 as a double


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit18 as text
%        str2double(get(hObject,'String')) returns contents of edit18 as a double


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cell_a.
function cell_a_Callback(hObject, eventdata, handles)
% hObject    handle to cell_a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cell_a contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cell_a

global seg img0_h lastsel;

h = get(get(img0_h,'Parent'),'Children');
h = findobj(h,'tag','bound');
sel = get(hObject,'Value');
str = get(hObject,'String');
if(~isempty(str))
    sel = str2num(str{sel});
    lastsel = sel;
    for(i=1:length(h))
        if(get(h(i),'UserData')==sel)
            set(h(i),'linewidth',3);
        else
            set(h(i),'linewidth',1);
        end
    end
end








% --- Executes during object creation, after setting all properties.
function cell_a_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cell_d.
function cell_d_Callback(hObject, eventdata, handles)
% hObject    handle to cell_d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cell_d contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cell_d

global seg img0_h lastsel;

h = get(get(img0_h,'Parent'),'Children');
h = findobj(h,'tag','bound');
sel = get(hObject,'Value');
str = get(hObject,'String');
if(~isempty(str))
    sel = str2num(str{sel});
    lastsel = sel;
    for(i=1:length(h))
        if(get(h(i),'UserData')==sel)
            set(h(i),'linewidth',3);
        else
            set(h(i),'linewidth',1);
        end
    end
end


% --- Executes during object creation, after setting all properties.
function cell_d_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton26.
function pushbutton26_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% remove selection from first list

cella = handles.cell_a;
idx = get(cella,'value');
l = get(cella,'String');
v = l{idx};
l(idx) = [];
set(cella,'String',l,'Value',1)

%add it to the second one...

celld = handles.cell_d;
l = get(celld,'String');
l{end+1} = v;
set(celld,'String',l,'Value',1);


% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



celld = handles.cell_d;
idx = get(celld,'value');
l = get(celld,'String');
v = l{idx};
l(idx) = [];
set(celld,'String',l,'Value',1)

%add it to the second one...

cella = handles.cell_a;
l = get(cella,'String');
l{end+1} = v;
set(cella,'String',l,'Value',1);




% --- Executes on button press in pushbutton28.
function pushbutton28_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cella = handles.cell_a;
la = get(cella,'String');
set(cella,'String',{},'Value',1)

%add it to the second one...

celld = handles.cell_d;
set(celld,'String',la,'Value',1);



% --- Executes on button press in pushbutton29.
function pushbutton29_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

celld = handles.cell_d;
ld = get(celld,'String');
set(celld,'String',{},'Value',1);

%add it to the second one...

cella = handles.cell_a;
set(cella,'String',ld,'Value',1);


% --- Executes during object creation, after setting all properties.
function traces_CreateFcn(hObject, eventdata, handles)
% hObject    handle to traces (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate traces

global traces_h trace_idx trace_period  trace_data;

traces_h = hObject;
set(hObject,'color',[0 0 0],'Box','on');
trace_idx = 1;
trace_period = 512; % how many points in the trace....


function animal_Callback(hObject, eventdata, handles)
% hObject    handle to animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of animal as text
%        str2double(get(hObject,'String')) returns contents of animal as a double

global animal datadir;

animal = get(hObject,'String');

if(~exist([datadir filesep animal],'dir'))
    r = questdlg('Directory does not exist. Do you want to creat it?','Question','Yes','No','Yes');
    switch(r)
        case 'Yes'
            mkdir([datadir filesep animal]);
    end
end

% --- Executes during object creation, after setting all properties.
function animal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global animal;
animal ='xx0';


function expt_Callback(hObject, eventdata, handles)
% hObject    handle to expt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of expt as text
%        str2double(get(hObject,'String')) returns contents of expt as a double

global experiment;

experiment = str2num(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function expt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to expt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global experiment;
experiment = 0;


function edit21_Callback(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit21 as text
%        str2double(get(hObject,'String')) returns contents of edit21 as a double


% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in savesel.
function savesel_Callback(hObject, eventdata, handles)
% hObject    handle to savesel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns savesel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from savesel

global savesel;

savesel= get(hObject,'Value');



% --- Executes during object creation, after setting all properties.
function savesel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to savesel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global savesel;
savesel = 1;


% --- Executes during object creation, after setting all properties.
function dirname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dirname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global datadir animal expt trial

datadir = 'd:\2pdata';
animal = 'xx0';
expt = 0;
trial = 0;


% --- Executes during object creation, after setting all properties.
function laserbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% laser_send(sprintf('LASER=%d',get(hObject,'Value')));

global laser_h;

laser_h = hObject;


% --- Executes on slider movement.
function low_Callback(hObject, eventdata, handles)
% hObject    handle to low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
end




% --- Executes during object creation, after setting all properties.
function low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function high_Callback(hObject, eventdata, handles)
% hObject    handle to high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider



global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
end


% --- Executes during object creation, after setting all properties.
function high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function gamma_Callback(hObject, eventdata, handles)
% hObject    handle to gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
end


% --- Executes during object creation, after setting all properties.
function gamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function grabb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grabb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global grabb_h;

grabb_h = hObject;


function gencm(low,high,gamma)

global cm scanbox_h;

x = (1:256)';
low = round(low*length(x));
high = round(high*length(x));

y(1:low*length(x)) = 0;
y(high+1:end) = 1;

y = (x-low).^gamma /(high-low)^gamma;
y(1:low) = 0;
y(high:end) = 1;

cm = repmat(y,[1 3]);
cm(end,2:3) = 0;  % red

cm = flipud(cm);

colormap(scanbox_h,cm); % set colormap


function appendcm(low,high,gamma)

global cm scanbox_h;

x = (1:256)';
low = round(low*length(x));
high = round(high*length(x));

y(1:low*length(x)) = 0;
y(high+1:end) = 1;

y = (x-low).^gamma /(high-low)^gamma;
y(1:low) = 0;
y(high:end) = 1;

cmold = cm;

cm = repmat(y,[1 3]);
cm(end,2:3) = 0;  % red

cm = flipud(cm);

cm = [cmold(2:2:end,:) ; cm(2:2:end,:)];

colormap(scanbox_h,cm); % set colormap



function unit_Callback(hObject, eventdata, handles)
% hObject    handle to unit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of unit as text
%        str2double(get(hObject,'String')) returns contents of unit as a double

global unit;
unit = str2num(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function unit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


global unit;
unit = 0;


% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% just get the laser status and print it...

set(handles.lstatus,'String',laser_status);


function laser_cb(obj,~)
global lstatus;

set(lstatus,'String',laser_status);

function qmotion_cb(obj,~)
global qserial axis_sel scanbox_h;

if(qserial.bytesavailable>0)
    cmd = fread(qserial,qserial.bytesavailable);
    h = guidata(scanbox_h);
    for(i=1:length(cmd))
        switch cmd(i)
            case 64 % x-
                if(axis_sel ~= 2)
                    eventdata.Character = '@';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = '!';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
            case 65 % x+
                
                if(axis_sel ~= 2)
                    eventdata.Character = '@';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = ')';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
                
            case 32 % z-
                if(axis_sel ~= 0)
                    eventdata.Character = '$';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = '!';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
            case 33 % z+
                
                if(axis_sel ~= 0)
                    eventdata.Character = '$';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = ')';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
            case 16 % y-
                
                if(axis_sel ~= 1)
                    eventdata.Character = '#';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = ')';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
            case 17 % y+
                if(axis_sel ~= 1)
                    eventdata.Character = '#';
                    scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                end
                eventdata.Character = '!';
                scanboxfig_WindowKeyPressFcn(obj, eventdata, h);
                
            otherwise
                
                sw = dec2bin(cmd(i)-240,4);
                
                if(sw(1)=='0' &&  sw(2)=='0')
                    set(h.popupmenu3,'Value',3);
                end
                if(sw(1)=='1' &&  sw(2)=='0')
                    set(h.popupmenu3,'Value',3);
                end
                if(sw(1)=='0' &&  sw(2)=='1')
                    set(h.popupmenu3,'Value',2);
                end
                if(sw(1)=='1' &&  sw(2)=='1')
                    set(h.popupmenu3,'Value',1);
                end
                
                popupmenu3_Callback(h.popupmenu3, [], h);
                
                if(sw(3)=='0' &&  sw(4)=='0')
                    set(h.rotated,'Value',3);
                end
                if(sw(3)=='1' &&  sw(4)=='0')
                    set(h.rotated,'Value',3);
                end
                if(sw(3)=='0' &&  sw(4)=='1')
                    set(h.rotated,'Value',2);
                end
                if(sw(3)=='1' &&  sw(4)=='1')
                    set(h.rotated,'Value',1);
                end
                
        end
    end
end



% --- Executes on button press in pushbutton32.
function pushbutton32_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img0_h animal experiment unit;

img = get(img0_h,'CData'); % get current image

save('img.mat','img');
[FileName,PathName] = uiputfile('*.mat');
if(~isempty(FileName))
    save([PathName FileName],'img');
end

% --- Executes on button press in pushbutton35.
function pushbutton35_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h;
zoom(scanbox_h,'toggle');


% --- Executes on button press in pushbutton36.
function pushbutton36_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


global scanbox_h;

pan(scanbox_h,'toggle');


% --- Executes on button press in pushbutton37.
function pushbutton37_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global scanbox_h img0_h;

zoom(scanbox_h,'off');
pan(scanbox_h,'off');

%set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
% WindowAPI(handles.scanboxfig,'setfocus')


% --- Executes on button press in pushbutton38.
function pushbutton38_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cm scanbox_h img0_h;

cm = flipud(gray(256));
newcm = histeq(get(img0_h,'Cdata'),cm);
cm(end,:) = [1 0.5 0];

colormap(scanbox_h,cm); % set colormap
drawnow;


% --- Executes on selection change in popupmenu10.
function popupmenu10_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu10


% --- Executes during object creation, after setting all properties.
function popupmenu10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider13_Callback(hObject, eventdata, handles)
% hObject    handle to slider13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider14_Callback(hObject, eventdata, handles)
% hObject    handle to slider14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in rotated.
function rotated_Callback(hObject, eventdata, handles)
% hObject    handle to rotated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rotated

global motormode motor_gain

motormode = get(hObject,'Value');

if(motormode == 3) % pivot
    global xpiv zpiv dmpos sbconfig;
    th = str2num(get(handles.thpos,'String'));
    xpiv = dmpos(3) * motor_gain(3) + sbconfig.obj_length/motor_gain(3) *sind(th);
    zpiv = dmpos(1) * motor_gain(1) - sbconfig.obj_length/motor_gain(1) *cosd(th);
end


% --- Executes on button press in pushbutton42.
function pushbutton42_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img0_h seg;

h = get(get(img0_h,'Parent'),'Children');
delete(findobj(h,'tag','bound'));
h = get(get(img0_h,'Parent'),'Children');
delete(findobj(h,'tag','pt'));

seg =[];
set(handles.cell_a,'String',[]);
set(handles.cell_d,'String',[]);




% --- Executes on button press in pushbutton43.
function pushbutton43_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton43 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img0_h


[FileName,PathName] = uigetfile('*.mat');
load([PathName FileName],'img','-mat');
set(img0_h,'CData',img); % get current image



function p1_Callback(hObject, eventdata, handles)
% hObject    handle to p1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of p1 as text
%        str2double(get(hObject,'String')) returns contents of p1 as a double

global p1;

p1 = str2num(get(hObject,'String'));



% --- Executes during object creation, after setting all properties.
function p1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to p1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global p1;
p1 = 0.6;




function p2_Callback(hObject, eventdata, handles)
% hObject    handle to p2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of p2 as text
%        str2double(get(hObject,'String')) returns contents of p2 as a double
global p2;

p2 = str2num(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function p2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to p2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global p2;
p2 = 30;


% --- Executes on button press in pushbutton44.
function pushbutton44_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton44 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img0_h lastsel seg;

h = get(get(img0_h,'Parent'),'Children');
h = findobj(h,'tag','bound');

seg.boundary{lastsel} = {};
seg.pixels{lastsel} = {};
for(i=1:length(h))
    if(get(h(i),'UserData')==lastsel)
        delete(h(i));
        seg.img(seg.img==lastsel)=0;
    end
end


str = get(handles.cell_a,'String');
idx = find(strcmp(num2str(lastsel),str));
if(~isempty(idx))
    str(idx) = [];
    set(handles.cell_a,'String',str,'Value',1);
end


str = get(handles.cell_d,'String');
idx = find(strcmp(num2str(lastsel),str));
if(~isempty(idx))
    str(idx) = [];
    set(handles.cell_d,'String',str,'Value',1);
end



function restore_seg

global seg img0_h img0_axis;


if(~isempty(seg))
    
    axis(get(img0_h,'Parent'));
    hold on;
    for(i=1:seg.ncell)
        b = seg.boundary{i};
        if(~isempty(b))
            for(j=1:length(b))
                bb = b{j};
                plot(bb(:,2),bb(:,1),'-','tag','bound','UserData',i,'color',[1 0.7 0]);
            end
        end
    end
    hold off;
    
end


% --- Executes on slider movement.
function tracegain_Callback(hObject, eventdata, handles)
% hObject    handle to tracegain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global trace_gain;

trace_gain = get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function tracegain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tracegain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

global trace_gain;

trace_gain = 1;

% --- Executes on button press in traceon.
function traceon_Callback(hObject, eventdata, handles)
% hObject    handle to traceon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of traceon



function p3_Callback(hObject, eventdata, handles)
% hObject    handle to p3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of p3 as text
%        str2double(get(hObject,'String')) returns contents of p3 as a double


% --- Executes during object creation, after setting all properties.
function p3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to p3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function p4_Callback(hObject, eventdata, handles)
% hObject    handle to p4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of p4 as text
%        str2double(get(hObject,'String')) returns contents of p4 as a double


% --- Executes during object creation, after setting all properties.
function p4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to p4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function tpos_Callback(hObject, eventdata, handles)
% hObject    handle to tpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function messages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to messages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global messages;

messages = hObject;



% --- Executes on button press in autostab.
function autostab_Callback(hObject, eventdata, handles)
% hObject    handle to autostab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autostab

global autostab img0_axis img0_h refs refctr Ns;

if(autostab)
    set(hObject,'String','Image Stabilization Off')
    autostab = 0;
    refs = [];
    refctr = [];
    delete(findobj(get(get(img0_h,'parent'),'children'),'tag','abox'));
else
    set(hObject,'String','Image Stabilization On')
    autostab = 1;
    axis(img0_axis);
    x=round(ginput_c(1));
    img = get(img0_h,'Cdata');
    refs = double(img(x(2)-Ns:x(2)+Ns,x(1)-Ns:x(1)+Ns));
    refs = refs - mean(refs(:));
    hold on
    plot([x(1)-Ns x(1)+Ns x(1)+Ns x(1)-Ns x(1)-Ns],[x(2)-Ns x(2)-Ns x(2)+Ns x(2)+Ns x(2)-Ns],'r:','tag','abox','linewidth',2)
    hold off;
    refctr = x;
end

% set(hObject,'enable','off'); drawnow; set(hObject,'enable','on');
%
% drawnow;
% WindowAPI(handles.scanboxfig,'setfocus')




% --- Executes during object creation, after setting all properties.
function autostab_CreateFcn(hObject, eventdata, handles)
% hObject    handle to autostab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global autostab Ns;

autostab=0;
Ns = 30;




function msg = laser_status

global laser_h shutter_h wave_h sbconfig;

msg = [];

switch sbconfig.laser_type
    
    case 'CHAMELEON'
        
        r = laser_send('PRINT LASER');
        
        switch(r(end))
            case '0'
                %msg = [msg 'Laser is in standby'];
                set(laser_h,'String','Laser is off','FontWeight','Normal','Value',0);
            case '1'
                %msg = [msg 'Laser in on'];
                set(laser_h,'String','Laser is on','FontWeight','Bold','Value',1);
            case '2'
                msg = [msg 'Laser of due to fault!'];
        end
        
        
        r = laser_send('PRINT KEYSWITCH');
        switch(r(end))
            case '0'
                msg = [msg 'Key is off'];
            case '1'
                msg = [msg  'Key is on'];
        end
        
        r = laser_send('PRINT SHUTTER');
        switch(r(end))
            case '0'
                %msg = [msg sprintf('\n') 'Shutter is closed'];
                set(shutter_h,'String','Shutter closed','FontWeight','Normal','Value',0);
                
            case '1'
                %msg = [msg sprintf('\n') 'Shutter is open'];
                set(shutter_h,'String','Shutter open','FontWeight','Bold','Value',1);
        end
        
        
        r = laser_send('PRINT TUNING STATUS');
        switch(r(end))
            case '0'
                msg = [msg sprintf('\n') 'Tuning is ready'];
            case '1'
                msg = [msg sprintf('\n') 'Tuning in progress'];
            case '2'
                msg = [msg sprintf('\n') 'Search for modelock in progress'];
            case '3'
                msg = [msg sprintf('\n') 'Recovery in progress'];
        end
        
        
        r = laser_send('PRINT MODELOCKED');
        switch(r(end))
            case '0'
                msg = [msg sprintf('\n') 'Standby...'];
            case '1'
                msg = [msg sprintf('\n') 'Modelocked!'];
            case '2'
                msg = [msg sprintf('\n') 'CW'];
        end
        
        % r = laser_send('PRINT WAVELENGTH');
        % r = r(end-3:end);
        % set(wave_h,'String',r);
        
    case 'MAITAI'
        
        r = laser_send('SHUTTER?');
        switch(r(end))
            case '0'
                set(shutter_h,'String','Shutter closed','FontWeight','Normal','Value',0);
                
            case '1'
                set(shutter_h,'String','Shutter open','FontWeight','Bold','Value',1);
        end
        
        r = laser_send('READ:PCTWARMEDUP?');
        msg = r;
        
        r = laser_send('READ:WAVELENGTH?');
        msg = [msg sprintf('\n') r];
        
end





% --- Executes on button press in pushbutton46.
function pushbutton46_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch(questdlg('Do you really want to retract the objective?'))
    case 'Yes'
        r = tri_send('SAP',4,0,1000);   % change velocity/acceleration for 'z'
        r = tri_send('SAP',5,0,1000);
        r = tri_send('MVP',1,0,128041);
        
        pause(6);
        
        popupmenu3_Callback(handles.popupmenu3,[],handles); % restore velocity
        eventdata.Character = '2';                          % select 'x' and update position...
        scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles);
end


% --- Executes on slider movement.
function slider18_Callback(hObject, eventdata, handles)
% hObject    handle to slider18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global boardHandle;

retCode = ...
    calllib('ATSApi', 'AlazarSetExternalClockLevel', ...
    boardHandle,		 ...	% HANDLE -- board handle
    double(get(hObject,'Value'))			 ...	% U32 --level in percent
    )



% --- Executes during object creation, after setting all properties.
function slider18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function udp_open

global sb_server;

if(~isempty(sb_server))
    udp_close;
end
sb_server=udp('localhost', 'LocalPort', 7000,'BytesAvailableFcn',@udp_cb);
fopen(sb_server);


function udp_close

global sb_server;

try
    fclose(sb_server);
    delete(sb_server);
catch
    sb_server = [];
end


function udp_cb(a,b)

global scanbox_h messages captureDone;

s = fgetl(a);   % read the message

switch(s(1))
    
    case 'A'                % set animal name
        an = s(2:end);
        h = findobj(scanbox_h,'Tag','animal');
        set(h,'String',an);
        f = get(h,'Callback');
        f(h,guidata(h));
        
    case 'E'                % set experiment number
        e = s(2:end);
        h = findobj(scanbox_h,'Tag','expt');
        set(h,'String',e);
        f = get(h,'Callback');
        f(h,guidata(h));
        
    case 'U'                % set unit number (imaging field numnber)
        u = s(2:end);
        h = findobj(scanbox_h,'Tag','unit');
        set(h,'String',u);
        f = get(h,'Callback');
        f(h,guidata(h));
        
    case 'M'                % add message...
        mssg = s(2:end);
        oldmssg = get(messages,'String');
        if(length(oldmssg)==0)
            set(messages,'String',{mssg});
        else
            oldmssg{end+1} = mssg;
            set(messages,'String',oldmssg);
            set(messages,'ListBoxTop',length(oldmssg));
            set(messages,'Value',length(oldmssg));
        end
        
    case 'C'                % clear message....
        set(messages,'String',{});  % clear messages...
        set(messages,'ListBoxTop',1);
        set(messages,'Value',1);
        
    case 'Z'                % press the zero button in the motor position box...
        
        h = findobj(scanbox_h,'Tag','zerobutton');
        f = get(h,'Callback');
        f(h,guidata(h));  % press the zero button....
        
    case 'P'               % move axis by um relative to current position
        
        global motor_gain origin scanbox_h
        
        r = [];
        
        mssg = s(2:end);
        ax = mssg(1);
        val = str2num(mssg(2:end));
        
        switch(ax)
            case 'x'
                val = val/motor_gain(3);
                r=tri_send('MVP',1,2,val);
                s = 'xpos';
                v =  motor_gain(3) * double(r.value-origin(3));
                
            case 'y'
                val = val/motor_gain(2);
                r=tri_send('MVP',1,1,val);
                s = 'ypos';
                v =  motor_gain(2)* double(r.value-origin(2));
                
            case 'z'
                val = val/motor_gain(1);
                r=tri_send('MVP',1,0,val);
                s = 'zpos';
                v =  motor_gain(1) * double(r.value-origin(1));
        end
        
        h = findobj(scanbox_h,'Tag',s);
        set(h,'String',sprintf('%.2f',v));
        
        drawnow;
        
    case 'O'        % go to origin
        
        h = findobj(scanbox_h,'Tag','originbutton');
        f = get(h,'Callback');
        f(h,guidata(h));  % press the origin button....
        
    case 'G'        % Go ... start scanning
        
        h = findobj(scanbox_h,'Tag','grabb');
        f = get(h,'Callback');
        f(h,guidata(h));  % press the grab button....
        
    case 'S'        % Stop scanning
        
        global captureDone;
        captureDone = 1;
        
end

% WindowAPI(handles.scanbox_fig,'setfocus');


% --- Executes on key press with focus on scanboxfig or any of its controls.
function scanboxfig_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to scanboxfig (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


global axis_sel mstep origin dmpos motormode sbconfig motor_gain scanbox_h xpiv zpiv

% read the angle of the objective
% this needs to be replaced by a rotary motor encoder

% we have to execute this only if the hObject is not a text object...!!

if(~ismember(eventdata.Character,{')','!','@','#','$','%'}))
    return;
end


th = str2num(get(handles.thpos,'String'));

if(~get(handles.motorlock,'Value'))
    r = [];
    
    switch(eventdata.Character)
        
        case ')'
            
            switch(motormode)
                
                case 1     % normal
                    
                    dmpos(axis_sel+1) = dmpos(axis_sel+1)+mstep(axis_sel+1);
                    r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
                    
                case 2  % rotate
                    
                    if((axis_sel==2 || axis_sel==0))
                        switch(axis_sel)
                            case 0
                                dmpos(1) = dmpos(1) + mstep(1)*cosd(th);
                                dmpos(3) = dmpos(3) + mstep(1)*motor_gain(1)/motor_gain(3)*sind(th);
                            case 2
                                dmpos(3) = dmpos(3) + mstep(3)*cosd(th);
                                dmpos(1) = dmpos(1) + mstep(3)*motor_gain(3)/motor_gain(1)*sind(th);
                        end
                        
%                         tri_send('SCO',0,2,dmpos(3));
%                         tri_send('SCO',0,0,dmpos(1));
%                         tri_send('MVP',2,hex2dec('45'),0);
                        
                         r = tri_send('MVP',0,2,dmpos(3));
                         r = tri_send('MVP',0,0,dmpos(1));
                    else
                        dmpos(axis_sel+1) = dmpos(axis_sel+1)-mstep(axis_sel+1);
                        r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
                    end
                    
                    
                case 3     %pivot 
                    
                    if(axis_sel==3)
                        
                        dmpos(4) = dmpos(4)+mstep(axis_sel+1);
                        th = dmpos(4) * motor_gain(4); 

                        dmpos(1) = zpiv + sbconfig.obj_length * cosd(th) / motor_gain(1);
                        dmpos(3) = xpiv - sbconfig.obj_length * sind(th) / motor_gain(3);
                                              
                        tri_send('SCO',0,0,dmpos(1));
                        tri_send('SCO',0,2,dmpos(3));
                        tri_send('SCO',0,3,dmpos(4));
                        tri_send('MVP',2,hex2dec('4d'),0);

                                                
%                         r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));               
%                         r = tri_send('MVP',0,2,dmpos(3)); %x
%                         r = tri_send('MVP',0,0,dmpos(1)); %z
%                         r = tri_send('MVP',0,3,dmpos(4)); %th
                    end
                    
            end
            
            
        case '!'
            
            switch(motormode)
                
                case 1     % normal
                    
                    dmpos(axis_sel+1) = dmpos(axis_sel+1)-mstep(axis_sel+1);
                    r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
                    
                case 2  % rotate
                    
                    if((axis_sel==2 || axis_sel==0))
                        switch(axis_sel)
                            case 0
                                dmpos(1) = dmpos(1) - mstep(1)*cosd(th);
                                dmpos(3) = dmpos(3) - mstep(1)*motor_gain(1)/motor_gain(3)*sind(th);
                            case 2
                                dmpos(3) = dmpos(3) - mstep(3)*cosd(th);
                                dmpos(1) = dmpos(1) - mstep(3)*motor_gain(3)/motor_gain(1)*sind(th);
                        end
                        
%                         tri_send('SCO',0,2,dmpos(3));
%                         tri_send('SCO',0,0,dmpos(1));
%                         tri_send('MVP',2,hex2dec('45'),0);
                        
                         r = tri_send('MVP',0,2,dmpos(3));
                         r = tri_send('MVP',0,0,dmpos(1));
                    else
                        dmpos(axis_sel+1) = dmpos(axis_sel+1)+mstep(axis_sel+1);
                        r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
                    end
                    
                    
                case 3     %pivot
                    
                    if(axis_sel==3)
                        
                        dmpos(4) = dmpos(4)-mstep(axis_sel+1);
                        th = dmpos(4) * motor_gain(4); 

                        dmpos(1) = zpiv + sbconfig.obj_length * cosd(th) / motor_gain(1);
                        dmpos(3) = xpiv - sbconfig.obj_length * sind(th) / motor_gain(3);
                        
                        tri_send('SCO',0,0,dmpos(1));
                        tri_send('SCO',0,2,dmpos(3));
                        tri_send('SCO',0,3,dmpos(4));
                        tri_send('MVP',2,hex2dec('4d'),0);
                        
%                         r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
%                         r = tri_send('MVP',0,2,dmpos(3)); %x
%                         r = tri_send('MVP',0,0,dmpos(1)); %z
%                         r = tri_send('MVP',0,3,dmpos(4)); %th
                    end
                    
            end
            
            
            %             if(get(handles.rotated,'Value') && (axis_sel==2 || axis_sel==0))
            %                 switch(axis_sel)
            %                     case 0
            %                         dmpos(1) = dmpos(1) - mstep(1)*cosd(th);
            %                         dmpos(3) = dmpos(3) - mstep(3)*sind(th);
            %
            %                     case 2
            %                         dmpos(3) = dmpos(3) - mstep(3)*cosd(th);
            %                         dmpos(1) = dmpos(1) - mstep(1)*sind(th);
            %                 end
            %                 r = tri_send('MVP',0,2,dmpos(3));
            %                 r = tri_send('MVP',0,0,dmpos(1));
            %             else
            %                 dmpos(axis_sel+1) = dmpos(axis_sel+1)-mstep(axis_sel+1);
            %                 r = tri_send('MVP',0,axis_sel,dmpos(axis_sel+1));
            %             end
            
        case '@'
            set(handles.xpos,'ForegroundColor',[1 0 0]);
            set(handles.ypos,'ForegroundColor',[0 0 0]);
            set(handles.zpos,'ForegroundColor',[0 0 0]);
            set(handles.thpos,'ForegroundColor',[0 0 0]);
            axis_sel = 2; % x
            
        case '#'
            set(handles.xpos,'ForegroundColor',[0 0 0]);
            set(handles.ypos,'ForegroundColor',[1 0 0]);
            set(handles.zpos,'ForegroundColor',[0 0 0]);
            set(handles.thpos,'ForegroundColor',[0 0 0]);
            axis_sel = 1; % y
            
        case '$'
            set(handles.xpos,'ForegroundColor',[0 0 0]);
            set(handles.ypos,'ForegroundColor',[0 0 0]);
            set(handles.zpos,'ForegroundColor',[1 0 0]);
            set(handles.thpos,'ForegroundColor',[0 0 0]);
            axis_sel = 0; % z
            
        case '%'
            set(handles.xpos,'ForegroundColor',[0 0 0]);
            set(handles.ypos,'ForegroundColor',[0 0 0]);
            set(handles.zpos,'ForegroundColor',[0 0 0]);
            set(handles.thpos,'ForegroundColor',[1 0 0]);
            axis_sel = 3; % th
            
    end
    
    global motor_gain   % gain is in um/step or deg/step for theta
    
    % update all positions... (necessary when in rotated mode...)
    
    mname = {'zpos','ypos','xpos','thpos'};
    v = zeros(1,4);
%     for(i=0:3)
%         r = tri_send('GAP',0,i,0);
%         v(i+1) =  motor_gain(i+1) * double(r.value-origin(i+1));  %%  (inches/rot) / (steps/rot) * 25400um
%     end

    for(i=0:3)
        v(i+1) =  motor_gain(i+1) * double(dmpos(i+1)-origin(i+1));  %%  (inches/rot) / (steps/rot) * 25400um
    end
    
    %     % Translate position to rotated axis if necessary...
    %
    %     if(motormode~=1)
    %         R = [cosd(th) sind(th);-sind(th) cosd(th)];
    %         if(axis_sel==0)
    %             R = inv(R);
    %         end
    %         vp = R* v([3 1])';
    %         v(3) = vp(1); v(1) = vp(2);
    %     end
    
    % Write the positions...
    
    for(i=0:3)
        h = findobj(scanbox_h,'Tag',mname{i+1});
        set(h,'String',sprintf('%.2f',v(i+1)));
        drawnow;
    end
    
    
end


% --- Executes on button press in pushbutton48.
function pushbutton48_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton48 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


r = tri_send('MVP',1,4,1500);

% --- Executes on button press in pushbutton49.
function pushbutton49_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton49 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

r = tri_send('MVP',1,4,-1500);



function frate_Callback(hObject, eventdata, handles)
% hObject    handle to frate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frate as text
%        str2double(get(hObject,'String')) returns contents of frate as a double


global nlines sbconfig;

frate = str2num(get(hObject,'String'));

if(isempty(frate))
    warndlg('Frame rate must be a number.  Resetting to 10fps');
    frate = 10;
    set(hObject,'String','10.0');
end

nlines = round(sbconfig.resfreq/frate);
sb_setline(nlines);
set(handles.lines,'String',num2str(nlines));
frame_rate = sbconfig.resfreq/nlines;
set(handles.frate,'String',sprintf('%2.2f',frame_rate));


% --- Executes during object creation, after setting all properties.
function frate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function low1_Callback(hObject, eventdata, handles)
% hObject    handle to low1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    gencm(low,high,gamma);
end


% --- Executes during object creation, after setting all properties.
function low1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to low1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function high1_Callback(hObject, eventdata, handles)
% hObject    handle to high1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    gencm(low,high,gamma);
end

% --- Executes during object creation, after setting all properties.
function high1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to high1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function gamma1_Callback(hObject, eventdata, handles)
% hObject    handle to gamma1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


global cm;

if(get(handles.pmtdisp,'Value')==4)
    
    low = get(handles.low,'Value');
    high = get(handles.high,'Value');
    gamma = get(handles.gamma,'Value');
    
    gencm(low,high,gamma);
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    appendcm(low,high,gamma);
    
else
    
    low = get(handles.low1,'Value');
    high = get(handles.high1,'Value');
    gamma = get(handles.gamma1,'Value');
    
    gencm(low,high,gamma);
end



% --- Executes during object creation, after setting all properties.
function gamma1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gamma1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function messages_Callback(hObject, eventdata, handles)
% hObject    handle to messages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of messages as text
%        str2double(get(hObject,'String')) returns contents of messages as a double


% --- Executes during object creation, after setting all properties.
function edit28_CreateFcn(hObject, eventdata, handles)
% hObject    handle to messages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function pmt1_Callback(hObject, eventdata, handles)
% hObject    handle to pmt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

sb_gain1(uint8(255*get(hObject,'Value')));
set(handles.pmt1txt,'String',sprintf('%1.2f',get(hObject,'Value')));

% --- Executes during object creation, after setting all properties.
function pmt1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function pmt0_Callback(hObject, eventdata, handles)
% hObject    handle to pmt0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

sb_gain0(uint8(255*get(hObject,'Value')));
set(handles.pmt0txt,'String',sprintf('%1.2f',get(hObject,'Value')));


% --- Executes during object creation, after setting all properties.
function pmt0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmt0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit29_Callback(hObject, eventdata, handles)
% hObject    handle to pmt0txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pmt0txt as text
%        str2double(get(hObject,'String')) returns contents of pmt0txt as a double


% --- Executes during object creation, after setting all properties.
function pmt0txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmt0txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit30_Callback(hObject, eventdata, handles)
% hObject    handle to pmt1txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pmt1txt as text
%        str2double(get(hObject,'String')) returns contents of pmt1txt as a double


% --- Executes during object creation, after setting all properties.
function pmt1txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pmt1txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pmtenable.
function pmtenable_Callback(hObject, eventdata, handles)
% hObject    handle to pmtenable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pmtenable

if(get(hObject,'Value'))
    set(handles.pmt0,'Enable','on');
    set(handles.pmt1,'Enable','on');
    pmt0_Callback(handles.pmt0, [], handles);
    pmt1_Callback(handles.pmt1, [], handles);
else
    set(handles.pmt0,'Enable','off');
    set(handles.pmt1,'Enable','off');
    sb_gain0(0);
    sb_gain1(0);
end


% --- Executes on button press in wc.
function wc_Callback(hObject, eventdata, handles)
% hObject    handle to wc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of wc


% configureLSB

function Configure_TTL


%
%     // Select output for LSB[0]
%     // REG_29[13..12] = 0 ==> LSB[0] = '0'  (default)
%     // REG_29[13..12] = 1 ==> LSB[0] = EXT TRIG input
%     // REG_29[13..12] = 2 ==> LSB[0] = AUX_IN[0] input
%     // REG_29[13..12] = 3 ==> LSB[0] = AUX_IN[1] input
%  
%     // select output for LSB[1]:
%     // REG_29[15..14] = 0 ==> LSB[1] = '0'  (default)
%     // REG_29[15..14] = 1 ==> LSB[1] = EXT TRIG input
%     // REG_29[15..14] = 2 ==> LSB[1] = AUX_IN[0] input
%     // REG_29[15..14] = 3 ==> LSB[1] = AUX_IN[1] input


global boardHandle;

v = libpointer('uint32Ptr',1); % value of register
newv = uint(32);               % new value...

retCode =  calllib('ATSApi', 'AlazarReadRegister', boardHandle, uint32(29), v, uint32(hex2dec('32145876')));

if (retCode ~= ApiSuccess)
    error('In AlazarReadRegister()');
end

newv = uint32(bin2dec(['1110' dec2bin(v.Value,14)]));       % write 11 10 means 3 2 -> LSB[1]= AUX_IN[1] and LSB[0] = AUX_IN[0]

retCode =  calllib('ATSApi', 'AlazarWriteRegister', boardHandle, uint32(29), newv, uint32(hex2dec('32145876')));

if (retCode ~= ApiSuccess)
    error('In AlazarWriteRegister()');
end


% --- Executes on slider movement.
function slider27_Callback(hObject, eventdata, handles)
% hObject    handle to slider27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider27_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider28_Callback(hObject, eventdata, handles)
% hObject    handle to slider28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider28_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu13.
function popupmenu13_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu13 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu13

switch get(hObject,'Value')
    case 1
        ot_mode('D');
        ot_current(0);
        set(handles.ot_slider,'Value',0);
    case 2
        ot_mode('Q');
    case 3
        ot_mode('T');
    case 4
        ot_mode('S');
end


% --- Executes during object creation, after setting all properties.
function popupmenu13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit31_Callback(hObject, eventdata, handles)
% hObject    handle to edit31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit31 as text
%        str2double(get(hObject,'String')) returns contents of edit31 as a double

ot_lower(str2num(get(hObject,'String'))*4095);



% --- Executes during object creation, after setting all properties.
function edit31_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit32_Callback(hObject, eventdata, handles)
% hObject    handle to edit32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit32 as text
%        str2double(get(hObject,'String')) returns contents of edit32 as a double

ot_upper(str2num(get(hObject,'String'))*4095);


% --- Executes during object creation, after setting all properties.
function edit32_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit33_Callback(hObject, eventdata, handles)
% hObject    handle to edit33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit33 as text
%        str2double(get(hObject,'String')) returns contents of edit33 as a double

ot_frequency(str2num(get(hObject,'String'))); % set the frequency...  in Hz


% --- Executes during object creation, after setting all properties.
function edit33_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function ot_slider_Callback(hObject, eventdata, handles)
% hObject    handle to ot_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

ot_current(get(hObject,'Value')*4095);


% --- Executes during object creation, after setting all properties.
function ot_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ot_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton51.
function pushbutton51_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global wcam wcam_roi;
wcam.ROIPosition = wcam_roi;
preview(wcam);


% --- Executes on key press with focus on expt and none of its controls.
function expt_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to expt (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function dalsa_exposure_Callback(hObject, eventdata, handles)
% hObject    handle to dalsa_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global dalsa dalsa_src img0_h;  % can only be called is dalsa is in preview mode...

closepreview(dalsa);
%dalsa_src.ExposureTimeAbs = get(hObject,'Value');

dalsa_src.ExposureTimeRaw = floor(get(hObject,'Value') * dalsa_src.MaxExposure);

preview(dalsa,img0_h);


% --- Executes during object creation, after setting all properties.
function dalsa_exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dalsa_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function dalsa_gain_Callback(hObject, eventdata, handles)
% hObject    handle to dalsa_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global dalsa dalsa_src img0_h;  % can only be called is dalsa is in preview mode...

closepreview(dalsa);
%dalsa_src.GainRaw = get(hObject,'Value');
dalsa_src.DigitalGainAll = get(hObject,'Value');
preview(dalsa,img0_h);


% --- Executes during object creation, after setting all properties.
function dalsa_gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dalsa_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider34_Callback(hObject, eventdata, handles)
% hObject    handle to slider34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global dalsa dalsa_src img0_h;  % can only be called is dalsa is in preview mode...

% closepreview(dalsa);
% dalsa_src.AcquisitionFrameRateAbs = get(hObject,'Value');
% preview(dalsa,img0_h);



% --- Executes during object creation, after setting all properties.
function slider34_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function c=scanbox_getconfig

global scanbox_h;

c.wavelength = str2num(get(findobj(scanbox_h,'Tag','wavelength'),'String'));
c.frames = str2num(get(findobj(scanbox_h,'Tag','frames'),'String'));
c.lines = str2num(get(findobj(scanbox_h,'Tag','lines'),'String'));
c.magnification = get(findobj(scanbox_h,'Tag','magnification'),'Value');
c.xpos = str2num(get(findobj(scanbox_h,'Tag','xpos'),'String'));
c.ypos = str2num(get(findobj(scanbox_h,'Tag','ypos'),'String'));
c.zpos = str2num(get(findobj(scanbox_h,'Tag','zpos'),'String'));
c.thpos = str2num(get(findobj(scanbox_h,'Tag','thpos'),'String'));

c.pmt0_gain = get(findobj(scanbox_h,'Tag','pmt0'),'Value');
c.pmt1_gain = get(findobj(scanbox_h,'Tag','pmt1'),'Value');

c.zstack.top = get(findobj(scanbox_h,'Tag','z_top'),'String');
c.zstack.bottom = get(findobj(scanbox_h,'Tag','z_top'),'String');
c.zstack.steps = get(findobj(scanbox_h,'Tag','z_steps'),'String');
c.zstack.size = get(findobj(scanbox_h,'Tag','z_size'),'String');

% --- Executes on button press in autoillum.
function autoillum_Callback(hObject, eventdata, handles)
% hObject    handle to autoillum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function z_top_Callback(hObject, eventdata, handles)
% hObject    handle to z_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of z_top as text
%        str2double(get(hObject,'String')) returns contents of z_top as a double

global z_top z_bottom z_steps z_size z_vals;

z_top = str2num(get(hObject,'String'));

if(isempty(z_top))
    warndlg('Parameter should be a number.  Resetting to zero.')
    z_top = 0;
    set(hObject,'String','0');
end

z_vals = linspace(z_bottom,z_top,z_steps);
z_size = mean(diff(z_vals));
set(handles.z_size,'String',num2str(z_size));

% --- Executes during object creation, after setting all properties.
function z_top_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function z_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to z_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of z_bottom as text
%        str2double(get(hObject,'String')) returns contents of z_bottom as a double

global z_top z_bottom z_steps z_size z_vals;

z_bottom = str2num(get(hObject,'String'));

if(isempty(z_bottom))
    warndlg('Parameter should be a number.  Resetting to zero.')
    z_bottom = 0;
    set(hObject,'String','0');
end

z_vals = linspace(z_top,z_bottom,z_steps);
z_size = mean(diff(z_vals));
set(handles.z_size,'String',num2str(z_size));



% --- Executes during object creation, after setting all properties.
function z_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function z_steps_Callback(hObject, eventdata, handles)
% hObject    handle to z_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of z_steps as text
%        str2double(get(hObject,'String')) returns contents of z_steps as a double

global z_top z_bottom z_steps z_size z_vals;

z_steps = str2num(get(hObject,'String'));

if(isempty(z_steps))
    warndlg('Parameter should be a number.  Resetting to zero.')
    z_bottom = 0;
    set(hObject,'String','0');
end


z_vals = linspace(z_top,z_bottom,z_steps);
z_size = mean(diff(z_vals));
set(handles.z_size,'String',num2str(z_size));


% --- Executes during object creation, after setting all properties.
function z_steps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function z_size_Callback(hObject, eventdata, handles)
% hObject    handle to z_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of z_size as text
%        str2double(get(hObject,'String')) returns contents of z_size as a double

global z_top z_bottom z_steps z_size z_vals;

z_size = str2num(get(hObject,'String'));

if(isempty(z_size))
    warndlg('Parameter should be a number.  Resetting to zero.')
    z_size = 0;
    set(hObject,'String','0');
end

z_vals = z_top:z_size:z_bottom;
set(handles.z_steps,'String',length(z_vals));


% --- Executes during object creation, after setting all properties.
function z_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton53.
function pushbutton53_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in pushbutton54.
function pushbutton54_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


global z_top z_bottom z_steps z_size z_vals;
global motor_gain origin scanbox_h;
global experiment;

z_vals = linspace(z_top,z_bottom,z_steps);

if(~isempty(z_vals) && ~any(isnan(z_vals)))
    
    z_vals = [z_vals(1) diff(z_vals)];  % the differences...
    
    for(val=z_vals)
        
        %move the motor relative to the beginning...
        
        val = round(val/motor_gain(1));
        r=tri_send('MVP',1,0,val);
        v =  motor_gain(1) * double(r.value-origin(1));
        set(handles.zpos,'String',sprintf('%.2f',v));
        drawnow;
        
        %scan
        h = findobj(scanbox_h,'Tag','grabb');
        f = get(h,'Callback');
        f(h,guidata(h));  % press the grab button....
        
        % update file number
        
        set(handles.expt,'String',sprintf('%03d',str2num(get(handles.expt,'String'))+1));
        experiment = experiment+1;
        
    end
    
end


% --- Executes on button press in eyet.
function eyet_Callback(hObject, eventdata, handles)
% hObject    handle to eyet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of eyet


% --- Executes on button press in pushbutton55.
function pushbutton55_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global eyecam eyecam_h eye_roi;

eyecam.ROIPosition = eye_roi;
eyecam_h = preview(eyecam);
colormap(ancestor(eyecam_h,'axes'),sqrt(gray(256)));


% --- Executes on button press in pushbutton56.
function pushbutton56_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global eyecam eyecam_h eye_roi;

closepreview(eyecam);
eyecam.ROIPosition = [0 0 eyecam.VideoResolution];
eye_roi = eyecam.ROIPosition;
start(eyecam);
pause(0.5);
stop(eyecam);
q = peekdata(eyecam,1);
figure('MenuBar','none','ToolBar','none','Name','Set ROI','NumberTitle','off');
imagesc(q); colormap(sqrt(gray(256))); axis off; truesize;

h = imrect(gca,[eyecam.VideoResolution/2-[160 112]/2 160 112]);
h.setFixedAspectRatioMode(true);
h.setResizable(false);
eyecam.ROIPosition = wait(h);
eye_roi = eyecam.ROIPosition;
close(gcf);
eyecam_h = preview(eyecam);
colormap(ancestor(eyecam_h,'axes'),sqrt(gray(256)));

% --- Executes on button press in pushbutton57.
function pushbutton57_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global eyecam eyecam_h eye_roi;
closepreview(eyecam);
eyecam.ROIPosition = [0 0 eyecam.VideoResolution];
eye_roi = eyecam.ROIPosition;
eyecam_h = preview(eyecam);
colormap(ancestor(eyecam_h,'axes'),sqrt(gray(256)));


% --- Executes on slider movement.
function slider40_Callback(hObject, eventdata, handles)
% hObject    handle to slider40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global wcam wcam_src;

closepreview(wcam);
wcam_src.Exposure = get(hObject,'Value');
preview(wcam);



% --- Executes during object creation, after setting all properties.
function slider40_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton58.
function pushbutton58_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global wcam wcam_h wcam_roi;

closepreview(wcam);
wcam.ROIPosition = [0 0 wcam.VideoResolution];
wcam_roi = wcam.ROIPosition;
start(wcam);
pause(0.5);
stop(wcam);
q = peekdata(wcam,1);
figure('MenuBar','none','ToolBar','none','Name','Set ROI','NumberTitle','off');
imagesc(q); colormap(sqrt(gray(256))); axis off; truesize;
h = imrect(gca,[wcam.VideoResolution/2-[192 192]/2 192 192]);
h.setFixedAspectRatioMode(true);
h.setResizable(false);
wcam.ROIPosition = wait(h);
wcam_roi = wcam.ROIPosition;
close(gcf);
wcam_h = preview(wcam);
colormap(ancestor(wcam_h,'axes'),sqrt(gray(256)));


% --- Executes on button press in pushbutton59.
function pushbutton59_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton59 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global wcam wcam_h wcam_roi;
closepreview(wcam);
wcam.ROIPosition = [0 0 wcam.VideoResolution];
wcam_roi = wcam.ROIPosition;
wcam_h = preview(wcam);
colormap(ancestor(wcam_h,'axes'),sqrt(gray(256)));


% --- Executes during object creation, after setting all properties.
function lstatus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

global lstatus;
lstatus = hObject;


% --- Executes on button press in ttlonline.
function ttlonline_Callback(hObject, eventdata, handles)
% hObject    handle to ttlonline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ttlonline

global ttlonline;

ttlonline = get(hObject,'Value');


% --- Executes on button press in pushbutton60.
function pushbutton60_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton60 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dmpos mpos;
mpos{1} = dmpos;

% for(i=0:3) 
%     tri_send('CCO',11,i,0);
% end



% --- Executes on button press in pushbutton61.
function pushbutton61_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton61 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mpos dmpos;

for(i=0:3)
   tri_send('SCO',0,i,mpos{1}(i+1));
end

v = zeros(4,2);

for(i=0:3)                      % current vel and acc
    r1 = tri_send('GAP',4,i,0);
    r2 = tri_send('GAP',5,i,0);
    v(i+1,1) = r1.value;
    v(i+1,2) = r2.value;
    tri_send('SAP',4,i,1200);
    tri_send('SAP',5,i,275);
end

tri_send('MVP',2,hex2dec('8f'),0);

set(hObject,'ForegroundColor',[1 0 0]);
drawnow;
st = 0;                         % wait for movement to finish
while(st==0)
    st = 1;
    for(i=0:3)
        r = tri_send('GAP',8,i,0);
        st = st * r.value;
    end
end
set(hObject,'ForegroundColor',[0 0 0]);
drawnow;


for(i=0:3)
    r1 = tri_send('SAP',4,i,v(i+1,1));
    r2 = tri_send('SAP',5,i,v(i+1,2));
end

dmpos = mpos{1};
update_pos;    

                        
% --- Executes on button press in pushbutton62.
function pushbutton62_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dmpos mpos;
mpos{2} = dmpos;

% for(i=0:3) 
%     tri_send('CCO',12,i,0);
% end

% --- Executes on button press in pushbutton63.
function pushbutton63_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mpos dmpos;

global mpos dmpos;

for(i=0:3)
   tri_send('SCO',0,i,mpos{2}(i+1));
end

v = zeros(4,2);

for(i=0:3)                      % current vel and acc
    r1 = tri_send('GAP',4,i,0);
    r2 = tri_send('GAP',5,i,0);
    v(i+1,1) = r1.value;
    v(i+1,2) = r2.value;
    tri_send('SAP',4,i,1200);
    tri_send('SAP',5,i,275);
end

tri_send('MVP',2,hex2dec('8f'),0);

set(hObject,'ForegroundColor',[1 0 0]);
drawnow;
st = 0;                         % wait for movement to finish
while(st==0)
    st = 1;
    for(i=0:3)
        r = tri_send('GAP',8,i,0);
        st = st * r.value;
    end
end
set(hObject,'ForegroundColor',[0 0 0]);
drawnow;

for(i=0:3)
    r1 = tri_send('SAP',4,i,v(i+1,1));
    r2 = tri_send('SAP',5,i,v(i+1,2));
end

dmpos = mpos{2};
update_pos;    


% --- Executes on button press in pushbutton64.
function pushbutton64_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton64 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dmpos mpos;
mpos{3} = dmpos;

% for(i=0:3) 
%     tri_send('CCO',13,i,0);
% end

% --- Executes on button press in pushbutton65.
function pushbutton65_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton65 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mpos dmpos;

for(i=0:3)
   tri_send('SCO',0,i,mpos{3}(i+1));
end

v = zeros(4,2);

for(i=0:3)                      % current vel and acc
    r1 = tri_send('GAP',4,i,0);
    r2 = tri_send('GAP',5,i,0);
    v(i+1,1) = r1.value;
    v(i+1,2) = r2.value;
    tri_send('SAP',4,i,1200);
    tri_send('SAP',5,i,275);
end

tri_send('MVP',2,hex2dec('8f'),0);

set(hObject,'ForegroundColor',[1 0 0]);
drawnow;
st = 0;                         % wait for movement to finish
while(st==0)
    st = 1;
    for(i=0:3)
        r = tri_send('GAP',8,i,0);
        st = st * r.value;
    end
end
set(hObject,'ForegroundColor',[0 0 0]);
drawnow;

for(i=0:3)
    r1 = tri_send('SAP',4,i,v(i+1,1));
    r2 = tri_send('SAP',5,i,v(i+1,2));
end

dmpos = mpos{3};
update_pos;    


% --- Executes on button press in pushbutton66.
function pushbutton66_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton66 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dmpos mpos;
mpos{4} = dmpos;

% for(i=0:3) 
%     tri_send('CCO',14,i,0);
% end

% --- Executes on button press in pushbutton67.
function pushbutton67_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton67 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global mpos dmpos;

for(i=0:3)
   tri_send('SCO',0,i,mpos{4}(i+1));
end

v = zeros(4,2);

for(i=0:3)                      % current vel and acc
    r1 = tri_send('GAP',4,i,0);
    r2 = tri_send('GAP',5,i,0);
    v(i+1,1) = r1.value;
    v(i+1,2) = r2.value;
    tri_send('SAP',4,i,1200);
    tri_send('SAP',5,i,275);
end

tri_send('MVP',2,hex2dec('8f'),0);

set(hObject,'ForegroundColor',[1 0 0]);
drawnow;
st = 0;                         % wait for movement to finish
while(st==0)
    st = 1;
    for(i=0:3)
        r = tri_send('GAP',8,i,0);
        st = st * r.value;
    end
end
set(hObject,'ForegroundColor',[0 0 0]);
drawnow;

for(i=0:3)
    r1 = tri_send('SAP',4,i,v(i+1,1));
    r2 = tri_send('SAP',5,i,v(i+1,2));
end

dmpos = mpos{4};
update_pos;    




function update_pos

global dmpos motor_gain origin scanbox_h; 

    mname = {'zpos','ypos','xpos','thpos'};
    v = zeros(1,4);
    
    for(i=0:3)
        v(i+1) =  motor_gain(i+1) * double(dmpos(i+1)-origin(i+1));  %%  (inches/rot) / (steps/rot) * 25400um
    end

    for(i=0:3)
        h = findobj(scanbox_h,'Tag',mname{i+1});
        set(h,'String',sprintf('%.2f',v(i+1)));
        drawnow;
    end
    
    


% --- Executes on button press in pushbutton68.
function pushbutton68_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton68 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global origin dmpos

for(i=0:2)
    r = tri_send('GAP',0,i,0);
    origin(i+1) = r.value;
end

dmpos(1:3) = origin(1:3);
update_pos;


% --- Executes on button press in text76.
function text76_Callback(hObject, eventdata, handles)
% hObject    handle to text76 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in text77.
function text77_Callback(hObject, eventdata, handles)
% hObject    handle to text77 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
