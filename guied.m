function varargout = guied(varargin)
% GUIED MATLAB code for guied.fig
%      GUIED, by itself, creates a new GUIED or raises the existing
%      singleton*.
%
%      H = GUIED returns the handle to a new GUIED or the handle to
%      the existing singleton*.
%
%      GUIED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIED.M with the given input arguments.
%
%      GUIED('Property','Value',...) creates a new GUIED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guied_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guied_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guied

% This code is done by Eduardo Villar
% Last Modified by GUIDE v2.5 22-Feb-2019 16:49:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guied_OpeningFcn, ...
                   'gui_OutputFcn',  @guied_OutputFcn, ...
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


% --- Executes just before guied is made visible.
function guied_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guied (see VARARGIN)

% Choose default command line output for guied
handles.output = hObject;

# NI-USB settings
#reset 
daq.reset;
#get device
handles.devices = daq.getDevices;
#start session
handles.s = daq.createSession('ni');  
% Set OutputChannel  counter (PulseGeneration)
[handles.ch,handles.idx] = addCounterOutputChannel(handles.s, 'Dev1', 'ctr0', 'PulseGeneration');
% Set dutycycle: If duty cycle is big, you might have problems setting high frequencies
handles.ch.DutyCycle = 0.01;

% Set trigger connection
[handles.ch,handles.idx] = addTriggerConnection(handles.s,'External',''Dev1/PFI0','StartTrigger');

% Set trigger condition property fo 
handles.c = handles.s.Connections(1);
handles.c.TriggerCondition = ' RisingEdge'
%KHz

% Set stimulation time in seconds 
handles.s.DurationInSeconds = 60;
% Setting AnalogueOutput
%[handles.ch,handles.idx] = addAnalogOutputChannel(handles.s, 'Dev1', 'ao0', 'Voltage');

%%  GUI setting 
%set(handles.pushbutton3,'String','Start','ForegroundColor','black','enable','on');
%set(handles.pushbutton4,'String','Stop','ForegroundColor','black','enable','on');
set(handles.pushbutton3,'BackgroundColor', [0.94 0.94 0.94]);
set(handles.pushbutton4,'BackgroundColor', [0.94 0.94 0.94]);

%% Creating Timer 
timer_obj = timer(...
    'StartFcn',         @user_timer_start, ...              % start function
    'TimerFcn',         {@user_timer_update, hObject}, ...  % timer function, has to specific the handle to the GUI,
    'StopFcn',          @user_timer_stop, ...               % stop function
    'ErrorFcn',         @user_timer_err, ...                % error function
    'ExecutionMode',    'fixedRate', ...                    %
    'Period',           1, ...                            % updates every xx seconds
    'TasksToExecute',   inf, ...
    'BusyMode',         'drop');

% save the timer object as application data
setappdata(hObject, 'timer_obj', timer_obj);% need to save it because we need to stop and delete it when quit

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes guied wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = guied_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Executes when user attempts to close the gui
function guied_CloseRequestFcn(hObject, eventdata, handles)

stop(getappdata(hObject, 'timer_obj'));     % stop the timer 

delete(getappdata(hObject, 'timer_obj'));   % delete the timer 

stop(handles.s)                             % stop NI-USB session 

release(handles.s)                          % and release channels

delete(hObject);                            % delete the gui

% This function is executed in every frame (optinal)
function user_timer_update(src, evt, handle)
handles = guihandles(handle);

if (toc == 5)

    %pushbutton4_Callback(src, evt, handle)
    
end
set(handles.text2,'String', datestr(datenum(0,0,0,0,0, toc),'MM:SS'));

function user_timer_start(src, evt)
tic;
disp('Timer was started!');

function user_timer_stop(src, evt)
disp('Timer was stopped.');

function user_timer_err(src, evt)
disp('Timer error.');

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

display('Starting Output Signal :) ...');

% Constant pulses

% start timer

timer_obj = getappdata(gcf, 'timer_obj');

start(timer_obj);

set(handles.pushbutton3,'string','Running','ForegroundColor','red','enable','off');
set(handles.pushbutton3,'BackgroundColor', 'green');
set(handles.pushbutton4,'BackgroundColor', [0.94 0.94 0.94]); % back to color gray

idx = get(handles.popupmenu1,'Value');

items = get(handles.popupmenu1,'String');

selectedItem = items{idx};

% Set Pulse Frequency
handles.ch.Frequency = str2double(selectedItem)*1000;

%display('is continuous true');

%handles.s.IsContinuous = true;
% Synchronize trigger

handles.s.AutoSynDSA = true;  % i am not sure about this, this is mostly used when you use multiple devices
% Receive trigger
dataIn = startForeground(handles.s);  % start trigger 

% Start sending data to NI-USB 
handles.s.startBackground;

guidata(hObject,handles)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pushbutton3,'String','Start','ForegroundColor','black','enable','on');
set(handles.pushbutton3,'BackgroundColor', [0.94 0.94 0.94]);

set(handles.pushbutton4,'String','Stop','ForegroundColor','black','enable','off');
set(handles.pushbutton4,'BackgroundColor', 'red');
set(handles.pushbutton4,'String','Stop','ForegroundColor','black','enable','on');

user_timer_stop(hObject, eventdata)

timer_obj = getappdata(gcf, 'timer_obj');

% stop timer
stop(timer_obj);

% stop NI-USB session 
stop(handles.s)    

% release NI-USB session 
release(handles.s)  

guidata(hObject,handles)

% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
contents = cellstr(get(hObject, 'String'));
choice = contents{get(hObject, 'Value')};

if (strcmp(choice, '3'))
    % a
    display('frequency : 3 KHz');
    
elseif (strcmp(choice, '10'))
    % b
    display('frequency : 10 KHz');
end

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
