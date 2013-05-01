function varargout = main(varargin)
% MAIN M-file for main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help main

% Last Modified by GUIDE v2.5 17-Oct-2007 18:43:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
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


% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Choose default command line output for main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


global ePic;                    % Creating ePic global object
    ePic = ePicKernel();     
    
global ControllerState;         % controller is off be default
    ControllerState = 0;    
    
global SensorsActivation;
    SensorsActivation=ones(1,8);
    SensorsActivation(8)=0;
    SensorsActivation(9)=0;
    
global pathDatas;               % path graph
    pathDatas = zeros(10000,2);
global pathDatai;
    pathDatai = 1;
    
global timer1_period;           % update timer
    timer1_period=0.1;
global timer1;   

global p_buffer;                % pointer for value save circular buffer
    p_buffer = 0;
global buff_size;
    buff_size = 1;
global valuesSensors;
    valuesSensors = zeros(1,3);

    axes(handles.axes_path);
    scatter(0,0); % clear plot
    set(handles.axes_path,'XTick',[]);
    set(handles.axes_path,'XTickLabel',[]);
    set(handles.axes_path,'YTick',[]);
    set(handles.axes_path,'YTickLabel',[]);

    img = imread('epuck.tif');
    axes(handles.axes_epuck);
    image(img);
    set(handles.axes_epuck,'XTick',[]);
    set(handles.axes_epuck,'XTickLabel',[]);
    set(handles.axes_epuck,'YTick',[]);
    set(handles.axes_epuck,'YTickLabel',[]);
    
    % timer 1 settings
    timer1 = timer('TimerFcn',@btm_timer1_Callback,'period',timer1_period);
    set(timer1,'ExecutionMode','fixedDelay');
    set(timer1,'BusyMode','drop');

    % Autodetect serial ports
    serialTmp = instrhwinfo('serial');
    if (size(serialTmp.SerialPorts,1) > 0)
        set(handles.str_port,'String',serialTmp.SerialPorts);
    else
        set(handles.str_port,'String','no port detected');
    end
    drawnow;


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Initialse controls
function ResetControls(handles)
    set(handles.ck_LED_1,'Value',0);
    set(handles.ck_LED_2,'Value',0);
    set(handles.ck_LED_3,'Value',0);
    set(handles.ck_LED_4,'Value',0);
    set(handles.ck_LED_5,'Value',0);
    set(handles.ck_LED_6,'Value',0);
    set(handles.ck_LED_7,'Value',0);
    set(handles.ck_LED_8,'Value',0);
    set(handles.ck_LED_B,'Value',0);
    set(handles.ck_LED_F,'Value',0);


% --- Executes on button press in btmConnect.
function btmConnect_Callback(hObject, eventdata, handles)
% hObject    handle to btmConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;      
global timer1;          % global variable for the timer
global timer1_period;   % global variable for the period of timer1
global handles_save;

Sel_Sensor_Callback(hObject, eventdata, handles);  % Initialise Sensor Selection

set(handles.txt_err_timer,'Visible','off');
set(handles.txt_timer_stop,'Visible','off');
port = get(handles.str_port,'String');
if length(port) > 1
    port = port{get(handles.str_port,'Value')};
end
if (strcmp(get(handles.str_port,'Enable'),'on') == 1)
    set(handles.btmConnect,'String','Connecting...');
    set(handles.btmConnect,'Enable','off');
    guidata(hObject, handles);
    drawnow();
    % Open serial connection and init timer
    [ePic result] = connect(ePic, port);
    if (result == 1)
        set(handles.str_port,'Enable','off');
        set(handles.btmConnect,'String','Disconnect');
        ResetControls(handles);
        % create and start timer. Save handles for timer callback function
        handles_save = handles;
        timer1_period = str2num(get(handles.str_time,'String'));
        set(timer1,'period',timer1_period);
        start(timer1);
    else
        % Connection error
        msgbox('Connection error. Try an other port or switch the e-puck on');
        set(handles.btmConnect,'String','Connect');
    end
    set(handles.btmConnect,'Enable','on');
else
    set(handles.btmConnect,'String','Disconnecting...');
    set(handles.btmConnect,'Enable','off');
    guidata(hObject, handles);
    drawnow();
    % Close serial connection and kill timer
    stop(timer1);
    [ePic result] = disconnect(ePic);
    if (result == 1)
        set(handles.str_port,'Enable','on');
        set(handles.btmConnect,'String','Connect');
        set(handles.btmConnect,'Enable','on');
    end
end
set(handles.txt_err_timer,'Visible','off');


% --- Executes on button press in ck_LED_0.
function ck_LED_0_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_0
global ePic;

if ( get(handles.ck_LED_0,'Value'))
    ePic = set(ePic,'ledON', 0);
else
    ePic = set(ePic,'ledOFF',0);
end


% --- Executes on button press in ck_LED_1.
function ck_LED_1_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_1
global ePic;

if ( get(handles.ck_LED_1,'Value'))
    ePic = set(ePic,'ledON', 1);
else
    ePic = set(ePic,'ledOFF',1);
end

% --- Executes on button press in ck_LED_2.
function ck_LED_2_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_2
global ePic;

if ( get(handles.ck_LED_2,'Value'))
    ePic = set(ePic,'ledON', 2);
else
    ePic = set(ePic,'ledOFF',2);
end

% --- Executes on button press in ck_LED_3.
function ck_LED_3_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_3
global ePic;

if ( get(handles.ck_LED_3,'Value'))
    ePic = set(ePic,'ledON', 3);
else
    ePic = set(ePic,'ledOFF',3);
end

% --- Executes on button press in ck_LED_4.
function ck_LED_4_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_4
global ePic;

if ( get(handles.ck_LED_4,'Value'))
    ePic = set(ePic,'ledON', 4);
else
    ePic = set(ePic,'ledOFF',4);
end

% --- Executes on button press in checkbox5.
function ck_LED_5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5
global ePic;

if ( get(handles.ck_LED_5,'Value'))
    ePic = set(ePic,'ledON', 5);
else
    ePic = set(ePic,'ledOFF',5);
end

% --- Executes on button press in checkbox6.
function ck_LED_6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6
global ePic;

if ( get(handles.ck_LED_6,'Value'))
    ePic = set(ePic,'ledON', 6);
else
    ePic = set(ePic,'ledOFF',6);
end

% --- Executes on button press in checkbox7.
function ck_LED_7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7
global ePic;

if ( get(handles.ck_LED_7,'Value'))
    ePic = set(ePic,'ledON', 7);
else
    ePic = set(ePic,'ledOFF',7);
end

% --- Executes on button press in checkbox8.
function ck_LED_8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox8
global ePic;

if ( get(handles.ck_LED_8,'Value'))
    ePic = set(ePic,'ledON', 10);
else
    ePic = set(ePic,'ledOFF',10);
end

% --- Executes on button press in ck_LED_B.
function ck_LED_B_Callback(hObject, eventdata, handles)
% hObject    handle to ck_LED_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_LED_B
global ePic;

if ( get(handles.ck_LED_B,'Value'))
    ePic = set(ePic,'ledON', 8);
else
    ePic = set(ePic,'ledOFF',8);
end

% --- Executes on button press in checkbox10.
function ck_LED_F_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox10
global ePic;

if ( get(handles.ck_LED_F,'Value'))
    ePic = set(ePic,'ledON', 9);
else
    ePic = set(ePic,'ledOFF',9);
end



% --- Executes on selection change in Sel_Sensor.
function Sel_Sensor_Callback(hObject, eventdata, handles)
% hObject    handle to Sel_Sensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Sel_Sensor contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Sel_Sensor

global ePic;

% disable update
ePic = updateDef(ePic, 'external',0);
set (handles.ck_autoAcc,'Value',0);

% for sensor data saving
buff_size_Callback(hObject, eventdata, handles);

sel_value = get(handles.Sel_Sensor,'Value');

% show/hide led selection 
if (sel_value == 9)
    set(handles.uipanel_LEDSelect,'Visible','on');
else
    set(handles.uipanel_LEDSelect,'Visible','off');
end

if (sel_value <=5)
    set (handles.ck_autoAcc,'Visible','off');
else
    set (handles.ck_autoAcc,'Visible','on');
end

ePic = set(ePic, 'external', sel_value);


% --- Executes during object creation, after setting all properties.
function Sel_Sensor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Sel_Sensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value1_Callback(hObject, eventdata, handles)
% hObject    handle to str_value1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value1 as text
%        str2double(get(hObject,'String')) returns contents of str_value1 as a double


% --- Executes during object creation, after setting all properties.
function str_value1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value2_Callback(hObject, eventdata, handles)
% hObject    handle to str_value2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value2 as text
%        str2double(get(hObject,'String')) returns contents of str_value2 as a double


% --- Executes during object creation, after setting all properties.
function str_value2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function str_value3_Callback(hObject, eventdata, handles)
% hObject    handle to str_value3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value3 as text
%        str2double(get(hObject,'String')) returns contents of str_value3 as a double


% --- Executes during object creation, after setting all properties.
function str_value3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ck_sensorLED_4.
function ck_sensorLED_4_Callback(hObject, eventdata, handles)
% hObject    handle to ck_sensorLED_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_sensorLED_4


% --- Executes on button press in ck_sensorLED_3.
function ck_sensorLED_3_Callback(hObject, eventdata, handles)
% hObject    handle to ck_sensorLED_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_sensorLED_3


% --- Executes on button press in ck_sensorLED_1.
function ck_sensorLED_1_Callback(hObject, eventdata, handles)
% hObject    handle to ck_sensorLED_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_sensorLED_1


% --- Executes on button press in ck_sensorLED_2.
function ck_sensorLED_2_Callback(hObject, eventdata, handles)
% hObject    handle to ck_sensorLED_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_sensorLED_2


% --- Executes on button press in ck_sensorLED_5.
function ck_sensorLED_5_Callback(hObject, eventdata, handles)
% hObject    handle to ck_sensorLED_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_sensorLED_5


% --- Executes on button press in btm_timer1.
function btm_timer1_Callback(hObject, eventdata, handles)
% hObject    handle to btm_timer1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tic;

global ePic;
global handles_save;
global valuesSensors;   % used for saving value to MATLAB workspace
global p_buffer;
global buff_size;
global pathDatas;       % used to plot path
global pathDatai;
global ControllerState;
global timer1_period;

ePic = update(ePic);                    % time step : read the requested values

% Selected sensor
selectedSensor = get(handles_save.Sel_Sensor,'Value');
selectedSensorValue = 0;

[val, up] = get(ePic, 'accel');     % Accelerometers
if (up >= 1)
    if (selectedSensor == 1)
        selectedSensorValue = val;
    end
end

[val, up] = get(ePic, 'proxi');     % Proximity sensors
if (up >= 1)
    set(handles_save.str_prox1,'String',val(1));
    set(handles_save.str_prox2,'String',val(2));
    set(handles_save.str_prox3,'String',val(3));
    set(handles_save.str_prox4,'String',val(4));
    set(handles_save.str_prox5,'String',val(5));
    set(handles_save.str_prox6,'String',val(6));
    set(handles_save.str_prox7,'String',val(7));
    set(handles_save.str_prox8,'String',val(8));
    
    if (selectedSensor == 2)
        selectedSensorValue = val;
    end
end

[val, up] = get(ePic, 'micro');     % Microphones
if (up >= 1)
    if (selectedSensor == 3)
        selectedSensorValue = val;
    end
end

[val, up] = get(ePic, 'light');     % Light sensors
if (up >= 1)
    if (selectedSensor == 4)
        selectedSensorValue = val;
    end
end

[val, up] = get(ePic, 'speed');     % Motors speed
if (up >= 1)
    set(handles_save.str_getLSpeed,'String',val(1));
    set(handles_save.str_getRSpeed,'String',val(2));
end

[val, up] = get(ePic, 'pos');       % Motors position
if (up >= 1)
    set(handles_save.str_getLPos,'String',val(1));
    set(handles_save.str_getRPos,'String',val(2));
end

[val, up] = get(ePic, 'floor');     % Floor sensors
if (up >= 1)
    if (selectedSensor == 5)
        selectedSensorValue = val;
    end
end

% External sensors --------------------------------
% Depend of the current selected sensor
if (selectedSensor == 10)     % five led IR sensor
    ledIR(1) = get(handles_save.ck_sensorLED_1,'Value');
    ledIR(2) = get(handles_save.ck_sensorLED_2,'Value');
    ledIR(3) = get(handles_save.ck_sensorLED_3,'Value');
    ledIR(4) = get(handles_save.ck_sensorLED_4,'Value');
    ledIR(5) = get(handles_save.ck_sensorLED_5,'Value');
    ePic = set(ePic,'ledIR',ledIR);
end

if (selectedSensor > 6)  % External sensor
    [val, up] = get(ePic, 'external');
    if (up > 0)
        if (selectedSensor==13)
            selectedSensorValue = val(1);
        else
            selectedSensorValue = val;
        end
    end
end

% Display selected sensor value in the global field
tmp_text = '';
for i=1:size(selectedSensorValue,2)
    tmp_text{i} = num2str(selectedSensorValue(i));
end
set(handles_save.txt_sensor,'String',tmp_text);

% Save values in global variable
p_buffer = p_buffer + 1;
if (buff_size>-1 && p_buffer>buff_size)
    set(handles_save.btm_SaveSensors,'BackgroundColor','g');
    p_buffer = 1;
end
if (size(selectedSensorValue,2) ~= size(valuesSensors,2))
    valuesSensors = zeros(buff_size,size(selectedSensorValue,2));
end
valuesSensors(p_buffer,:) = selectedSensorValue;

% Update odometry -----------------------------------------
ePic = updateOdometry(ePic);
[val, up] = get(ePic,'odom');
if (up > 0)
    set(handles_save.txt_odoX,'String',num2str(1000 * val(1)));
    set(handles_save.txt_odoY,'String',num2str(1000 * val(2)));
    set(handles_save.txt_odoT,'String',num2str(val(3)));
end

% Graph e-puck path ---------------------------------------
if (get(handles_save.ck_drawPath,'Value')==1)
    [val, up] = get(ePic,'odom');
    if (up > 0)
        % Refresh path graph  
        pathDatas(pathDatai,:) = val(1:2);
        pathDatai = pathDatai+1;
        if (pathDatai==10001) 
            pathDatai = 1;
        end
    end
end     

% Controller execution ------------------------------------
% (ControllerState==-1 means that switching off is in progress)
if (((get(handles_save.ck_controller,'Value')==1) || (ControllerState==-1)) && (get(ePic,'connectionState') == 1))
    tmp = get(handles_save.str_controller,'String');
    tmp = tmp{get(handles_save.str_controller,'Value')};
    try
        eval(strtok(tmp,'.'));
    catch
        set(handles_save.txt_timer_stop,'Visible','on');
        set(handles_save.ck_controller,'Value',0);
        err =lasterror;
        assignin('base', 'ERROR_msg_controller',err);
        error_file = '';
        for i=1:size(err.stack,1)
            error_file = sprintf('%sFile : %s \n Name : %s, Line : %d \n\n',error_file ,err.stack(i,1).file, err.stack(i,1).name, err.stack(i,1).line);
        end
        error_msg = sprintf('Error identifier : \n %s \n \n Error message : \n %s \n \n %s', err.identifier,err.message,error_file);
        msgbox(error_msg, 'Controller error','error');
    end
end


% Check if timer is not too slow
if (timer1_period<toc)
    set(handles_save.txt_err_timer,'Visible','on');
end


% --- Executes on button press in ck_autoAcc.
function ck_autoAcc_Callback(hObject, eventdata, handles)
% hObject    handle to ck_autoAcc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_autoAcc
% Refresh the sensor selection
global ePic;

ePic = updateDef(ePic, 'external',get(handles.ck_autoAcc,'Value'));


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on button press in btm_stop.
function btm_stop_Callback(hObject, eventdata, handles)
% hObject    handle to btm_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;
ePic=set(ePic,'speed', [0 0]);

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



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_getLSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to str_getLSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_getLSpeed as text
%        str2double(get(hObject,'String')) returns contents of str_getLSpeed as a double


% --- Executes during object creation, after setting all properties.
function str_getLSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_getLSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function str_getRSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to str_getRSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_getRSpeed as text
%        str2double(get(hObject,'String')) returns contents of str_getRSpeed as a double


% --- Executes during object creation, after setting all properties.
function str_getRSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_getRSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function str_getLPos_Callback(hObject, eventdata, handles)
% hObject    handle to str_getLPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_getLPos as text
%        str2double(get(hObject,'String')) returns contents of str_getLPos as a double


% --- Executes during object creation, after setting all properties.
function str_getLPos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_getLPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_getRPos_Callback(hObject, eventdata, handles)
% hObject    handle to str_getRPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_getRPos as text
%        str2double(get(hObject,'String')) returns contents of str_getRPos as a double


% --- Executes during object creation, after setting all properties.
function str_getRPos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_getRPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ck_updateMotorS.
function ck_updateMotorS_Callback(hObject, eventdata, handles)
% hObject    handle to ck_updateMotorS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_updateMotorS




% --- Executes on button press in ck_updateMotorP.
function ck_updateMotorP_Callback(hObject, eventdata, handles)
% hObject    handle to ck_updateMotorP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_updateMotorP





function str_setLSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to str_setLSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_setLSpeed as text
%        str2double(get(hObject,'String')) returns contents of str_setLSpeed as a double


% --- Executes during object creation, after setting all properties.
function str_setLSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_setLSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_setRSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to str_setRSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_setRSpeed as text
%        str2double(get(hObject,'String')) returns contents of str_setRSpeed as a double


% --- Executes during object creation, after setting all properties.
function str_setRSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_setRSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_setLPos_Callback(hObject, eventdata, handles)
% hObject    handle to str_setLPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_setLPos as text
%        str2double(get(hObject,'String')) returns contents of str_setLPos as a double


% --- Executes during object creation, after setting all properties.
function str_setLPos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_setLPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_setRPos_Callback(hObject, eventdata, handles)
% hObject    handle to str_setRPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_setRPos as text
%        str2double(get(hObject,'String')) returns contents of str_setRPos as a double


% --- Executes during object creation, after setting all properties.
function str_setRPos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_setRPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btm_setMotorS.
function btm_setMotorS_Callback(hObject, eventdata, handles)
% hObject    handle to btm_setMotorS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;
ePic=set(ePic,'speed', [str2num(get(handles.str_setLSpeed,'String')) str2num(get(handles.str_setRSpeed,'String'))]);

% --- Executes on button press in btm_setMotorP.
function btm_setMotorP_Callback(hObject, eventdata, handles)
% hObject    handle to btm_setMotorP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function axes_joystick_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_joystick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_joystick
%axes(handles.axes_joystick);axis off;
  %          drawnow;
  



% --- Executes on button press in btm_changeTime.
function btm_changeTime_Callback(hObject, eventdata, handles)
% hObject    handle to btm_changeTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global timer1;
global timer1_period;
% If connected to the e-puck : change the time between two data refresh
stop (timer1);
set(handles.txt_err_timer,'Visible','off');
timer1_period = str2num(get(handles.str_time,'String'));
set(timer1,'TimerFcn',@btm_timer1_Callback,'Period',timer1_period);
set(handles.txt_timer_stop,'Visible','off');
set(handles.txt_err_timer,'Visible','off');
start(timer1);


function str_time_Callback(hObject, eventdata, handles)
% hObject    handle to str_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_time as text
%        str2double(get(hObject,'String')) returns contents of str_time as a double


% --- Executes during object creation, after setting all properties.
function str_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in ck_controller.
function ck_controller_Callback(hObject, eventdata, handles)
% hObject    handle to ck_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global ControllerState;
global ePic;

if (get(ePic,'connectionState') == 1)

  % Hint: get(hObject,'Value') returns toggle state of ck_controller
  if (get(hObject,'Value')==1)
    ControllerState = 1;  % go to controller initialization state
  else
    ControllerState = -1; % go to controller deinitialization state
  end      

else
  set(hObject,'Value',1-get(hObject,'Value'));
end  

set(handles.txt_timer_stop,'Visible','off');
    
function str_controller_Callback(hObject, eventdata, handles)
% hObject    handle to str_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_controller as text
%        str2double(get(hObject,'String')) returns contents of str_controller as a double


% --- Executes during object creation, after setting all properties.
function str_controller_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on mouse press over axes background.
function axes_joystick_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_joystick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;

vect=get(handles.axes_joystick,'CurrentPoint');
side =  vect(1,1);
speed = 1000 * vect(1,2);
if (side > 0) 
    vl = speed;
    vr = speed- side*speed;
else
    vl = speed + side*speed;
    vr = speed;
end

set(handles.str_setLSpeed,'String',round(vl));
set(handles.str_setRSpeed,'String',round(vr));

ePic=set(ePic,'speed', [str2num(get(handles.str_setLSpeed,'String')) str2num(get(handles.str_setRSpeed,'String'))]);



function str_prox8_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox8 as text
%        str2double(get(hObject,'String')) returns contents of str_prox8 as a double


% --- Executes during object creation, after setting all properties.
function str_prox8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox7_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox7 as text
%        str2double(get(hObject,'String')) returns contents of str_prox7 as a double


% --- Executes during object creation, after setting all properties.
function str_prox7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox6_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox6 as text
%        str2double(get(hObject,'String')) returns contents of str_prox6 as a double


% --- Executes during object creation, after setting all properties.
function str_prox6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox5_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox5 as text
%        str2double(get(hObject,'String')) returns contents of str_prox5 as a double


% --- Executes during object creation, after setting all properties.
function str_prox5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox1_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox1 as text
%        str2double(get(hObject,'String')) returns contents of str_prox1 as a double


% --- Executes during object creation, after setting all properties.
function str_prox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox2_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox2 as text
%        str2double(get(hObject,'String')) returns contents of str_prox2 as a double


% --- Executes during object creation, after setting all properties.
function str_prox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox3_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox3 as text
%        str2double(get(hObject,'String')) returns contents of str_prox3 as a double


% --- Executes during object creation, after setting all properties.
function str_prox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_prox4_Callback(hObject, eventdata, handles)
% hObject    handle to str_prox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_prox4 as text
%        str2double(get(hObject,'String')) returns contents of str_prox4 as a double


% --- Executes during object creation, after setting all properties.
function str_prox4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_prox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value4_Callback(hObject, eventdata, handles)
% hObject    handle to str_value4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value4 as text
%        str2double(get(hObject,'String')) returns contents of str_value4 as a double


% --- Executes during object creation, after setting all properties.
function str_value4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value5_Callback(hObject, eventdata, handles)
% hObject    handle to str_value5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value5 as text
%        str2double(get(hObject,'String')) returns contents of str_value5 as a double


% --- Executes during object creation, after setting all properties.
function str_value5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value6_Callback(hObject, eventdata, handles)
% hObject    handle to str_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value6 as text
%        str2double(get(hObject,'String')) returns contents of str_value6 as a double


% --- Executes during object creation, after setting all properties.
function str_value6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value7_Callback(hObject, eventdata, handles)
% hObject    handle to str_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value7 as text
%        str2double(get(hObject,'String')) returns contents of str_value7 as a double


% --- Executes during object creation, after setting all properties.
function str_value7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_value8_Callback(hObject, eventdata, handles)
% hObject    handle to str_value8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_value8 as text
%        str2double(get(hObject,'String')) returns contents of str_value8 as a double


% --- Executes during object creation, after setting all properties.
function str_value8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_value8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ck_updateProximity.
function ck_updateProximity_Callback(hObject, eventdata, handles)
% hObject    handle to ck_updateProximity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_updateProximity
    


% --- Executes on button press in ck_autoSaveVal.
function ck_autoSaveVal_Callback(hObject, eventdata, handles)
% hObject    handle to ck_autoSaveVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_autoSaveVal
Sel_Sensor_Callback(hObject, eventdata, handles);



% --- Executes on button press in btm_SaveSensors.
function btm_SaveSensors_Callback(hObject, eventdata, handles)
% hObject    handle to btm_SaveSensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global valuesSensors;
global p_buffer;
global buff_size;

persistent cpt;
if isempty(cpt)
   cpt = 0;
end


if (buff_size>-1)
    if (size(valuesSensors,1)~=1 && p_buffer > 0)
            valuesSensors = [valuesSensors(p_buffer+1:buff_size,:); valuesSensors(1:p_buffer,:)];
    end
else
    valuesSensors = valuesSensors(1:p_buffer,:);
end

cpt = cpt + 1;
tmp = sprintf('sensors_%03d',cpt);
assignin('base', tmp,valuesSensors);



% --- Executes during object creation, after setting all properties.
function btmConnect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to btmConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called





% --- Executes on button press in ck_drawPath.
function ck_drawPath_Callback(hObject, eventdata, handles)
% hObject    handle to ck_drawPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ck_drawPath


% --- Executes on button press in btm_erase.
function btm_erase_Callback(hObject, eventdata, handles)
% hObject    handle to btm_erase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pathDatas;
global pathDatai;
global ePic;

pathDatas = zeros(10000,2);
pathDatai = 1;

ePic = reset(ePic,'odom');

setappdata(gcbf,'running',true);

axes(handles.axes_path);

scatter(0,0); % clear plot
set(handles.axes_path,'XTick',[]);
set(handles.axes_path,'XTickLabel',[]);
set(handles.axes_path,'YTick',[]);
set(handles.axes_path,'YTickLabel',[]);

drawnow;





% --- Executes during object creation, after setting all properties.
function ck_drawPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ck_drawPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%btm_erase_Callback();




function str_width_Callback(hObject, eventdata, handles)
% hObject    handle to str_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_width as text
%        str2double(get(hObject,'String')) returns contents of str_width as a double


% --- Executes during object creation, after setting all properties.
function str_width_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sel_zoom_Callback(hObject, eventdata, handles)
% hObject    handle to sel_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sel_zoom as text
%        str2double(get(hObject,'String')) returns contents of sel_zoom as a double


% --- Executes during object creation, after setting all properties.
function sel_zoom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sel_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function str_heigth_Callback(hObject, eventdata, handles)
% hObject    handle to str_heigth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_heigth as text
%        str2double(get(hObject,'String')) returns contents of str_heigth as a double


% --- Executes during object creation, after setting all properties.
function str_heigth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_heigth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3


% --- Executes on button press in btm_Capture.
function btm_Capture_Callback(hObject, eventdata, handles)
% hObject    handle to btm_Capture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global timer1;
global ePic;

% transfert the picture
stop (timer1);
ePic = updateDef(ePic,'image',2);
ePic = updateImage(ePic);
imagedata = get(ePic,'image');
start(timer1);

% display image 1
setappdata(gcbf,'running',true);
axes(handles.axes_picture1);
image(imagedata);
set(handles.axes_picture1,'XTick',[]);
set(handles.axes_picture1,'XTickLabel',[]);
set(handles.axes_picture1,'YTick',[]);
set(handles.axes_picture1,'YTickLabel',[]);

% display image 2
imagedata2 = filter_image2(imagedata);
axes(handles.axes_picture2);
image(imagedata2);
set(handles.axes_picture2,'XTick',[]);
set(handles.axes_picture2,'XTickLabel',[]);
set(handles.axes_picture2,'YTick',[]);
set(handles.axes_picture2,'YTickLabel',[]);

% Update
drawnow;
    


% --- Executes on button press in btm_setCamParam.
function btm_setCamParam_Callback(hObject, eventdata, handles)
% hObject    handle to btm_setCamParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global ePic;

heigth = str2num(get(handles.str_heigth,'String'));
width = str2num(get(handles.str_width,'String'));
switch get(handles.sel_zoom,'Value')
    case 1 
        val_zoom = 1;
    case 2
        val_zoom = 4;
    otherwise
        val_zoom = 8;
end
mode = get(handles.sel_imgmode,'Value')-1;

ePic=set(ePic,'camMode', mode);
ePic=set(ePic,'camSize', [width heigth]);
ePic=set(ePic,'camZoom', val_zoom);


function str_saveName_Callback(hObject, eventdata, handles)
% hObject    handle to str_saveName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of str_saveName as text
%        str2double(get(hObject,'String')) returns contents of str_saveName as a double


% --- Executes during object creation, after setting all properties.
function str_saveName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_saveName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in sel_imgmode.
function sel_imgmode_Callback(hObject, eventdata, handles)
% hObject    handle to sel_imgmode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns sel_imgmode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sel_imgmode


% --- Executes during object creation, after setting all properties.
function sel_imgmode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sel_imgmode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




% --- Executes during object creation, after setting all properties.
function axes_epuck_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_epuck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_epuck



% --- Executes on mouse press over axes background.
function axes_epuck_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_epuck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

global ePic;
global timer1;

if (get(ePic,'connectionState') == 1)
    stop(timer1);
    delete(timer1);
    clear('timer1');
    ePic = disconnect(ePic);
end

delete(hObject);








% --- Executes on button press in btm_Refreshgraph.
function btm_Refreshgraph_Callback(hObject, eventdata, handles)
% hObject    handle to btm_Refreshgraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pathDatas;
global timer1;

% transfert the picture
stop (timer1);
setappdata(gcbf,'running',true);

axes(handles.axes_path);

scatter(pathDatas(:,1),pathDatas(:,2));
set(handles.axes_path,'XTick',[]);
set(handles.axes_path,'XTickLabel',[]);
set(handles.axes_path,'YTick',[]);
set(handles.axes_path,'YTickLabel',[]);

drawnow;
start(timer1);


% --- Executes on button press in btm_browsw.
function btm_browsw_Callback(hObject, eventdata, handles)
% hObject    handle to btm_browsw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filename = uigetfile;
if (filename == 0)
else
    tmp_str = get(handles.str_controller,'String');
    for i=1:9
        tmp_str{11-i} = tmp_str{10-i};
    end
    tmp_str{1} = filename;
    set(handles.str_controller,'String',tmp_str);
end





% --- Executes on button press in btm_add_com.
function btm_add_com_Callback(hObject, eventdata, handles)
% hObject    handle to btm_add_com (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = inputdlg('Please enter the com port to add. Format : COMx','Add a port');
if (size(answer,1) == 1)
    tmp = get(handles.str_port,'String');
    if (length(tmp) > 1 )
        for i=1:length(tmp)
            answer{i+1} = tmp{i};
        end
    end
    set(handles.str_port,'String',answer);
end


% --- Executes on selection change in str_port.
function str_port_Callback(hObject, eventdata, handles)
% hObject    handle to str_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns str_port contents as cell array
%        contents{get(hObject,'Value')} returns selected item from str_port


% --- Executes during object creation, after setting all properties.
function str_port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to str_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function txt_sensor_Callback(hObject, eventdata, handles)
% hObject    handle to txt_sensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_sensor as text
%        str2double(get(hObject,'String')) returns contents of txt_sensor as a double


% --- Executes during object creation, after setting all properties.
function txt_sensor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_sensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over txt_timer_stop.
function txt_timer_stop_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to txt_timer_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'Visible','Off');



% --- Executes on selection change in buff_size.
function buff_size_Callback(hObject, eventdata, handles)
% hObject    handle to buff_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns buff_size contents as cell array
%        contents{get(hObject,'Value')} returns selected item from buff_size
global p_buffer;
global buff_size;
global valuesSensors;

p_buffer = 0;
tmp = get(handles.buff_size,'String');
val = get(handles.buff_size,'Value');
if (val~=10)
    if (val > 0)
        buff_size = str2num(tmp{val});
    end
    
    valuesSensors = zeros(buff_size,3);
    set(handles.btm_SaveSensors,'BackgroundColor','r');
else
    buff_size=-1;
    valuesSensors=zeros(1000,3);
    set(handles.btm_SaveSensors,'BackgroundColor','g');
end

% --- Executes during object creation, after setting all properties.
function buff_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to buff_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btm_buffer_state.
function btm_buffer_state_Callback(hObject, eventdata, handles)
% hObject    handle to btm_buffer_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in btm_save_images.
function btm_save_images_Callback(hObject, eventdata, handles)
% hObject    handle to btm_save_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;

persistent cpt;
if isempty(cpt)
   cpt = 0;
end

imagedata = get(ePic,'image');
imagedata2 = filter_image2(imagedata);

cpt = cpt + 1;
tmp1 = sprintf('image_%03d_org',cpt);
tmp2 = sprintf('image_%03d_fil',cpt);
assignin('base', tmp1,imagedata);
assignin('base', tmp2,imagedata2);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





function txt_odoX_Callback(hObject, eventdata, handles)
% hObject    handle to txt_odoX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_odoX as text
%        str2double(get(hObject,'String')) returns contents of txt_odoX as a double


% --- Executes during object creation, after setting all properties.
function txt_odoX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_odoX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_odoY_Callback(hObject, eventdata, handles)
% hObject    handle to txt_odoY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_odoY as text
%        str2double(get(hObject,'String')) returns contents of txt_odoY as a double


% --- Executes during object creation, after setting all properties.
function txt_odoY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_odoY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_odoT_Callback(hObject, eventdata, handles)
% hObject    handle to txt_odoT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_odoT as text
%        str2double(get(hObject,'String')) returns contents of txt_odoT as a double


% --- Executes during object creation, after setting all properties.
function txt_odoT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_odoT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in btm_ode_reset.
function btm_ode_reset_Callback(hObject, eventdata, handles)
% hObject    handle to btm_ode_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ePic;

ePic = set(ePic,'odom',[0 0 0]);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over txt_err_timer.
function txt_err_timer_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to txt_err_timer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Visible','Off');


% --- Executes on button press in btm_resetSensors.
%function btm_resetSensors_Callback(hObject, eventdata, handles)
% hObject    handle to btm_resetSensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btm_ResetSensors.
function btm_ResetSensors_Callback(hObject, eventdata, handles)
% hObject    handle to btm_ResetSensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global valuesSensors;
global p_buffer;
global buff_size;

p_buffer=0;
if (buff_size>-1)
    valuesSensors=zeros(buff_size,size(valuesSensors,2));
    set(handles.btm_SaveSensors,'BackgroundColor','r');
else
    valuesSensors=zeros(1000,size(valuesSensors,2));
    set(handles.btm_SaveSensors,'BackgroundColor','g');
end

% --------------------------------------------------------------------
function menu_Sensors_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Sensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_Accel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Accel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(1)==1)
    SensorsActivation(1)=0;
    set(handles.menu_Accel,'Checked','off');
    ePic=deactivate(ePic,'accel');
else
    set(handles.menu_Accel,'Checked','on');
    SensorsActivation(1)=1;
    ePic=activate(ePic,'accel',1);
end


% --------------------------------------------------------------------
function menu_Proximity_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Proximity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(2)==1)
    SensorsActivation(2)=0;
    set(handles.menu_Proximity,'Checked','off');
    ePic=deactivate(ePic,'proxi');
else
    set(handles.menu_Proximity,'Checked','on');
    SensorsActivation(2)=1;
    ePic=activate(ePic,'proxi',1);
end


% --------------------------------------------------------------------
function menu_Light_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Light (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(3)==1)
    SensorsActivation(3)=0;
    set(handles.menu_Light,'Checked','off');
    ePic=deactivate(ePic,'light');
else
    set(handles.menu_Light,'Checked','on');
    SensorsActivation(3)=1;
    ePic=activate(ePic,'light',1);
end



% --------------------------------------------------------------------
function menu_Micro_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Micro (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(4)==1)
    SensorsActivation(4)=0;
    set(handles.menu_Micro,'Checked','off');
    ePic=deactivate(ePic,'micro');
else
    set(handles.menu_Micro,'Checked','on');
    SensorsActivation(4)=1;
    ePic=activate(ePic,'micro',1);
end


% --------------------------------------------------------------------
function menu_MotorSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to menu_MotorSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(5)==1)
    SensorsActivation(5)=0;
    set(handles.menu_MotorSpeed,'Checked','off');
    ePic=deactivate(ePic,'speed');
else
    set(handles.menu_MotorSpeed,'Checked','on');
    SensorsActivation(5)=1;
    ePic=activate(ePic,'speed',1);
end


% --------------------------------------------------------------------
function menu_Wheel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Wheel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(6)==1)
    SensorsActivation(6)=0;
    set(handles.menu_Wheel,'Checked','off');
    ePic=deactivate(ePic,'pos');
%We also deactivate odometry if there is no encoders
    SensorsActivation(7)=0;
    set(handles.menu_Odometry,'Checked','off');
    ePic=deactivate(ePic,'odom');
else
    set(handles.menu_Wheel,'Checked','on');
    SensorsActivation(6)=1;
    ePic=activate(ePic,'pos',1);
end


% --------------------------------------------------------------------
function menu_Odometry_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Odometry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(7)==1)
    SensorsActivation(7)=0;
    set(handles.menu_Odometry,'Checked','off');
    ePic=deactivate(ePic,'odom');
else
    set(handles.menu_Odometry,'Checked','on');
    SensorsActivation(7)=1;
    ePic=activate(ePic,'odom',1);
    % We want to activate encoders to use odometry
    set(handles.menu_Wheel,'Checked','on');
    SensorsActivation(6)=1;
    ePic=activate(ePic,'pos',1);
    
end


% --------------------------------------------------------------------
function menu_floor_Callback(hObject, eventdata, handles)
% hObject    handle to menu_floor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(8)==1)
    SensorsActivation(8)=0;
    set(handles.menu_floor,'Checked','off');
    ePic=deactivate(ePic,'floor');
else
    set(handles.menu_floor,'Checked','on');
    SensorsActivation(7)=1;
    ePic=activate(ePic,'floor',1);
end



% --------------------------------------------------------------------
function menu_External_Callback(hObject, eventdata, handles)
% hObject    handle to menu_External (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SensorsActivation;
global ePic;
if (SensorsActivation(9)==1)
    SensorsActivation(9)=0;
    set(handles.menu_External,'Checked','off');
    ePic=deactivate(ePic,'external');
else
    set(handles.menu_External,'Checked','on');
    SensorsActivation(9)=1;
    ePic=activate(ePic,'external',1);
end




