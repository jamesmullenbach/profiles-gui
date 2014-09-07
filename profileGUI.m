function varargout = profileGUI(varargin)
% PROFILEGUI MATLAB code for profileGUI.fig
%      PROFILEGUI, by itself, creates a new PROFILEGUI or raises the existing
%      singleton*.
%
%      H = PROFILEGUI returns the handle to a new PROFILEGUI or the handle to
%      the existing singleton*.
%
%      PROFILEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROFILEGUI.M with the given input arguments.
%
%      PROFILEGUI('Property','Value',...) creates a new PROFILEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before profileGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to profileGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help profileGUI

% Last Modified by GUIDE v2.5 18-Oct-2013 12:51:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @profileGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @profileGUI_OutputFcn, ...
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


% --- Executes just before profileGUI is made visible.
function profileGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to profileGUI (see VARARGIN)

% Choose default command line output for profileGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.PxSize = 1;
handles.ProfileWidth = 2;
handles.filename = 'data.xls';
handles.timelapse = false;
guidata(hObject, handles);

% UIWAIT makes profileGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = profileGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function OutputName_Callback(hObject, eventdata, handles)
% hObject    handle to OutputName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OutputName as text
%        str2double(get(hObject,'String')) returns contents of OutputName as a double
handles.filename = get(hObject, 'String');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function OutputName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OutputName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Select_Run.
function Select_Run_Callback(hObject, eventdata, handles)
% hObject    handle to Select_Run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.timelapse
    data = helper(handles);
else
    [filename path] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
    '*.*','All Files' }, 'Select first image in series');
    [fname2 path2] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
    '*.*','All Files' }, 'Select last image in series'); 

    num1 = str2double(filename(filename>=48 & filename<=57));
    num2 = str2double(fname2(fname2>=48 & fname2<=57));
    num_images = num2 - num1 + 1;

    width = handles.ProfileWidth / handles.PxSize - 1;
    width = round(width/2);

    num_profiles = inputdlg('How many profiles do you need?', 'Profile Count', 1, {'1'});
    num_profiles = str2double(num_profiles{1});

    %now we have the width, what files we need to run over, and how many lines
    %we want in each file. Now we iterate over the lines, creating a cell array
    %containing the data  - each cell is a different line with columns
    %specifying intensity values for each image in the time series
    im = imread(filename);
    imagesc(im);
    hline = imline;
    for n = 1:num_profiles
        positions{n} = wait(hline); %gathers different coordinates for lines
        beep; %feedback
    end
    %positions attained, now run programs to rotate images and return 
    %intensity values.

    filename_permanent = filename;
    for n = 1:num_profiles
        filename = filename_permanent;
        [B p1 p2 theta] = linerotate(im, positions{n});%rotation script
        data{n} = zeros(p2(2) - p1(2) + 1, num_images + 1);
        data{n}(:, 1) = handles.PxSize*(1:size(data{n}, 1))'; %initializes cell
        I = Iplot(B, p1, p2, width); %gets intensity data
        data{n}(1:length(I), 2) = I'; %adds first line data
        names{1} = filename;
        for i = 1:(num_images - 1) %this will add data from all successive images for this line
            num = str2double(filename(filename>=48 & filename <=57));
            num = num + 1;
            if handles.numbernames
                filename = [num2str(num) '.tif'];
            else
                filename(filename>=48 & filename<=57) = num2str(num);
            end
            img = imread(filename); %selects and gets image matrix for next timeseries image
            BB = imrotate(img, -theta); %rotates this image with same angle
            I = Iplot(BB, p1, p2, width); %finds intensity data of the same line
            data{n}(:,i+2) = I'; %adds values to data cell for current line
            names{i+1} = filename;
        end
        data{n}(1:2, end+1:end+2) = [p1;p2]; %adds coordinates to cell
        figure(n); plot(data{n}(:,1), data{n}(:, 2:end-2)); title(sprintf('Average Intensity Profile #%d', n)); xlabel('Distance(um)'); ylabel('Intensity'); legend(names);
        xlswrite(handles.filename, data{n}, n);
    end
end
handles.data = data;
guidata(hObject, handles);


function PxSize_Callback(hObject, eventdata, handles)
% hObject    handle to PxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PxSize as text
%        str2double(get(hObject,'String')) returns contents of PxSize as a double
handles.PxSize = str2double(get(hObject, 'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function PxSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ProfileWidth_Callback(hObject, eventdata, handles)
% hObject    handle to ProfileWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ProfileWidth as text
%        str2double(get(hObject,'String')) returns contents of ProfileWidth as a double
handles.ProfileWidth = str2double(get(hObject, 'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ProfileWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ProfileWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in timelapse.
function timelapse_Callback(hObject, eventdata, handles)
% hObject    handle to timelapse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of timelapse
handles.timelapse = get(hObject, 'Value');
guidata(hObject, handles);


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
shell_name = strtok(handles.filename, '.');
saveas(gcf, shell_name, 'fig');

function data = helper(handles)
[filename path] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
    '*.*','All Files' }, 'Select first image in series');
[fname2 path2] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
    '*.*','All Files' }, 'Select last image in series');

num1 = str2double(filename(filename>=48 & filename<=57));
num2 = str2double(fname2(fname2>=48 & fname2<=57));
num_images = num2 - num1 + 1;

width = handles.ProfileWidth / handles.PxSize - 1;
width = round(width/2);

for n = 1:num_images
    mlen = 1;
    len = [];
    num_profiles = inputdlg('How many profiles do you need?', 'Profile Count', 1, {'1'});
    num_profiles = str2double(num_profiles{1});
    test{n} = filename;
    assignin('base', 'test', test);
    im = imread(filename);
    imagesc(im);
    hline = imline;
    for i = 1:num_profiles
        positions{i} = wait(hline); %gathers different coordinates for lines
        beep; %feedback
    end
    for m = 1:num_profiles
        [B p1 p2] = linerotate(im, positions{m});
        I = Iplot(B, p1, p2, width);
        len(m) = length(I);
        mlen = max(len);
        data{n}(mlen,num_profiles+1) = 0;
        data{n}(1:length(I), m + 1) = I';
        data{n}(2:3, end+1:end+2) = positions{m};
        names{m} = sprintf('Profile #%d', m);
    end
    data{n}(:,1) = handles.PxSize*(1:mlen)';
    figure(n); plot(data{n}(:,1), data{n}(1:end, 2:num_profiles+1)); xlabel('Distance (um)'); ylabel('Intensity');
    title(sprintf('Average Intensity, Cell Image %d', n)); legend(names);
    uiwait(n);
    xlswrite(handles.filename, data{n}, n);
    num = str2double(filename(filename>=48 & filename <=57));
    num = num + 1;
    filename(filename>=48 & filename<=57) = num2str(num);
end

function [B, P1, P2, theta] = linerotate(im, position)
%Opens image in filename
%Lets user draw a line from one pixel to another
%Rotates the image so that the line is straight from left to right
%Saves rotated image, start/endpoint of straight line in rotated image

% center = round(size(im)/2); center(end) = [];
% im(center(1), center(2), 1) = 255;
h = position(:,1);
v = position(:,2); % avoids 'indices must be integers' error
center = round(size(im)/2); center = center(1:2);
newcoords = [h - center(2), center(1) - v];
theta = atan2((v(1)-v(2)),(h(2)-h(1)));
pos = [cos(theta) sin(theta);-sin(theta) cos(theta)]*newcoords';
h_new = pos(1,:);
v_new = pos(2,:);
theta = 180*theta/pi;
B = imrotate(im, -theta);
new_cent = round(size(B)/2); new_cent = new_cent(1:2);
% x_corr = round(size(B,2) - (y_new + new_cent(2)));
% y_corr = round(x_new + new_cent(1));
v_corr = round(new_cent(1) - v_new);
h_corr = round(h_new + new_cent(2));
% B(v_corr(1), h_corr(1):h_corr(2), 1) = 255; %for debugging
% B(new_cent(1), new_cent(2), 1) = 255;
% image(B);
P1 = [v_corr(1) h_corr(1)];
P2 = [v_corr(2) h_corr(2)];

function I = Iplot(im, P1, P2, width)
%Calculates average intensity of pixels over a certain width along a line
%takes in image matrix, start and end points of a horizontal line
%P1 and P2 are the center of the rectangle over which intensity is measured
%width determines how many pixels above/below center on bar

n = 1;
for h = P1(2):P2(2)
    I(n) = mean(mean(im(P1(1)-width:P1(1)+width, h, :)));
    n = n + 1;
end


% --- Executes on button press in numbernames.
function numbernames_Callback(hObject, eventdata, handles)
% hObject    handle to numbernames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of numbernames
handles.numbernames = get(hObject, 'Value');
guidata(hObject, handles);