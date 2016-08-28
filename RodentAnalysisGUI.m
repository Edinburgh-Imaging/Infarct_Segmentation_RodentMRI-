function varargout = RodentAnalysisGUI(varargin)
% RODENTANALYSISGUI MATLAB code for RodentAnalysisGUI.fig
% This is a GUI used for the semi-automated analysis of brain T2-weighted 
% MRI images in rodent models of focal cerebral ischaemia for the 
% measurement of infarct volume.
%
% Use the GUI:
% Please see the README text file.
%
% Edit the GUI:
% >> guide
% 
% Last Modified: 28 August 2016
% Copyright (c) 2016, Xenios Milidonis

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RodentAnalysisGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RodentAnalysisGUI_OutputFcn, ...
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


% _________________________________________________________________________
% --- Executes just before RodentAnalysisGUI is made visible.
function RodentAnalysisGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.

global imagefolder;  % output

% Choose default command line output for RodentAnalysisGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Set the current directory as the starting path to look for the images.
imagefolder = pwd;

% Set the current date and time as the first output to the GUI's log window.
set(handles.listbox_log, 'String', datestr(now));

% Move the GUI to the centre of the screen.
movegui(hObject, 'center');

% Hide the axes values from all axes objects.
set(handles.axes_inputimage, 'XTick', []);
set(handles.axes_inputimage, 'YTick', []);
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);
set(handles.axes_histogram, 'FontSize', 7);

% Set some default parameters.
set(handles.popup_show, 'Value', 1);
set(handles.radiobutton_stack, 'Value', 1);
set(handles.radiobutton_slice, 'Value', 0);
set(handles.text_meanf, 'String', 1);
set(handles.text_sdf, 'String', 2.1);

% Read and display the tick/x marks on some push buttons.
tick = imread('tick.png');
set(handles.pushbutton_donedraw, 'cdata', tick);
xmark = imread('xmark.png');
set(handles.pushbutton_canceldraw, 'cdata', xmark);

% Disable some objects.
set(handles.pushbutton_loadipsi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadipsi, 'Enable', 'off');
set(handles.pushbutton_loadroi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadroi, 'Enable', 'off');
set(handles.pushbutton_drawroi, 'BusyAction', 'cancel');
set(handles.pushbutton_drawroi, 'Enable', 'off');
set(handles.pushbutton_volume, 'BusyAction', 'cancel');
set(handles.pushbutton_volume, 'Enable', 'off');
set(handles.pushbutton_edit, 'BusyAction', 'cancel');
set(handles.pushbutton_edit, 'Enable', 'off');
set(handles.pushbutton_loadtoedit, 'BusyAction', 'cancel');
set(handles.pushbutton_loadtoedit, 'Enable', 'off');
set(handles.checkbox_loadtoedit, 'Value', 0);
set(handles.checkbox_loadtoedit, 'BusyAction', 'cancel');
set(handles.checkbox_loadtoedit, 'Enable', 'off');
set(handles.checkbox_saveimages, 'BusyAction', 'queue')
set(handles.checkbox_saveimages, 'Enable', 'on')
set(handles.popup_show, 'BusyAction', 'queue')
set(handles.popup_show, 'Enable', 'on')
set(handles.slider_outputslices, 'Enable', 'off');

% Global variables must be cleared, otherwise they remain in workspace.
clearvars -global -except imagefolder;

% UIWAIT makes RodentAnalysisGUI wait for user response (see UIRESUME)
% uiwait(handles.rodentanalysisfigure);

% --- Outputs from this function are returned to the command line.
function varargout = RodentAnalysisGUI_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;


% _________________________________________________________________________
% --- Executes on button press in pushbutton_loaddata.
function pushbutton_loaddata_Callback(hObject, eventdata, handles)

clearvars -global -except imagefolder;

global imagefolder;     % input
global centralslice;    % outputs
global editmask;
global editvertices;
global imagename;
global imagesize;
global maxvaluevol;
global nametosaveas;
global editedvolmask;
global numofslices;
global roimask;
global roivertices;
global threshold;
global vol;
global voladjusted;

warning('off', 'all')

% Open UI to select input image stack and updade imagefolder.
[imagename, imagefolder] = uigetfile(fullfile(imagefolder, '*.tif'),... 
    'Please select a TIFF image sequence');
imagepath = fullfile(imagefolder, imagename);
nametosaveas = imagename(1:end-4);

% Get the number of slices in the image.
info = imfinfo(imagepath);
numofslices = numel(info);

% Show loaded image name in log window listbox_log...
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg = sprintf('Loaded %s', imagename);
newmsg = ['<HTML><b>', newmsg]; % make it bold
set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
%     ... and make its scroll bar move at the bottom.
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);

% -----------------ADJUST THE DATA AND ESTIMATE PARAMETERS-----------------
% Call stacktomatrix.m to transform the TIFF stack into a 3D matrix. This
% will be passed to GUI figures for visualisation and uipanel_plot to plot 
% the histogram of the original data.
vol = stacktomatrix(imagepath);

% Find the central slice. For even numofslices choose the upper slice.
centralslice = ceil((numofslices + 1) / 2); 

% Call adjustintensity3D to create a contrast-adjusted volume to be passed 
% for visualisation in the the GUI's 'Analysed Data' figure. Adjust
% contrast based on central slice and exclude pixels with minimum value.
voladjusted =...
    adjustintensity3D(vol, 'basedonslice', 'no', 'yes', centralslice);

% Take a note of the image size to be passed on for creating masks.
imagesize = size(vol(:, :, 1));

% Show the central slice of the stack with contrast adjustment.
axes(handles.axes_inputimage);
imshow(voladjusted(:, :, centralslice));
set(handles.axes_inputimage, 'XTick', []);
set(handles.axes_inputimage, 'YTick', []);

% Zero the 3D matrices where the coordinates of points of manual drawing
% are saved, and corresponding masks. 
roivertices = zeros(50, 2, numofslices);
editvertices = zeros(50, 2, numofslices);
roimask = zeros(2, 2, 2);
editmask = zeros(2, 2, 2);
editedvolmask = zeros(2, 2, 2);
threshold = 1;

% ----------------------SET DEFAULT PARAMETERS ON GUI----------------------
% Show the central slice number in text_inputslicenumber.
set(handles.text_inputslicenumber, 'String',...
    sprintf('%d/%d', centralslice, numofslices));

% Set image slider's initial position, min, max and step.
set(handles.slider_inputslices, 'Value', centralslice);
set(handles.slider_inputslices, 'Min', 1);
set(handles.slider_inputslices, 'Max', numofslices);
if numofslices == 1
    set(handles.slider_inputslices, 'SliderStep', [1, 1]);
else
    set(handles.slider_inputslices, 'SliderStep',...
        [1 / (numofslices - 1), 1 / (numofslices - 1)]);
end

% Show image's histogram (default is stack histogram), excluding the 
% minimum value just in case it is taken by many pixels.
set(handles.radiobutton_stack, 'Value', 1);
set(handles.radiobutton_slice, 'Value', 0);
maxvaluevol = max(vol(:));
axes(handles.axes_histogram);
imhist(vol(vol > min(vol(:))), 500); 
axis([0 maxvaluevol 0 inf])
set(handles.axes_histogram, 'FontSize', 7);
    
% Set the image resolution, if found in the header.
if isfield(info(1), 'XResolution') && ~isempty(info(1).XResolution)
    xres = info(1).XResolution;
    hpixsize = 1/xres;
    set(handles.text_xres, 'String', hpixsize);
end
if isfield(info(1), 'YResolution') && ~isempty(info(1).YResolution)
    yres = info(1).YResolution;
    vpixsize = 1/yres;
    set(handles.text_yres, 'String', vpixsize);
end

% Set the default number of slices to be analysed.
set(handles.text_firstslice, 'String', 1);
set(handles.text_lastslice, 'String', numofslices);

% Enable/disable some objects.
set(handles.pushbutton_loadipsi, 'BusyAction', 'queue');
set(handles.pushbutton_loadipsi, 'Enable', 'on');
set(handles.pushbutton_loadroi, 'BusyAction', 'queue');
set(handles.pushbutton_loadroi, 'Enable', 'on');
set(handles.pushbutton_drawroi, 'BusyAction', 'queue');
set(handles.pushbutton_drawroi, 'Enable', 'on');


% _________________________________________________________________________
% --- Executes on slider movement.
function slider_inputslices_Callback(hObject, eventdata, handles)

global numofslices;  % inputs
global threshold;
global vol;
global voladjusted;

% Get the current slice number from the slider.
sliderslice = round(get(hObject, 'Value'));

% Show the contrast adjusted image.
axes(handles.axes_inputimage);
imshow(voladjusted(:, :, sliderslice));
set(handles.axes_inputimage, 'XTick', []);
set(handles.axes_inputimage, 'YTick', []);

% Plot the histogram of individual slices of the original stack, excluding
% the minimum value just in case it is taken by many pixels.
histogrambutton = get(handles.radiobutton_slice, 'Value');
axes(handles.axes_histogram);
if histogrambutton == 1 
    slice = vol(:, :, sliderslice);
    maxvalueslice = max(max(slice));
    imhist(slice(slice > min(slice(:))), 500);
    axis([0 maxvalueslice 0 inf])
    set(handles.axes_histogram, 'FontSize', 7);
    
    % Show intensities above threshold with a different colour.
    y = imhist(slice(slice > min(slice(:))), 500);
    x = linspace(0, 1, 500)';
    hold on
    y = y(x > threshold);
    x = x(x > threshold);
    stem(x, y, 'Marker', 'none')
    hold off
end

% Show the slice number in text_inputslicenumber.
set(handles.text_inputslicenumber, 'String',...
    sprintf('%d/%d', sliderslice, numofslices));


% _________________________________________________________________________
% --- Executes when selected object is changed in uipanel_plot.
function uipanel_plot_SelectionChangeFcn(hObject, eventdata, handles)

global maxvaluevol;  % inputs
global threshold;
global vol;

% Get the tag of the selected button.
histogrambutton = get(eventdata.NewValue, 'Tag');

% If the stack button is selected then plot its histogram, otherwise rely 
% on slider_inputslices to plot individual slice histograms. Exclude the
% minimum value just in case it is taken by many pixels.
axes(handles.axes_histogram);
if strcmp(histogrambutton, 'radiobutton_stack')  
    imhist(vol(vol > min(vol(:))), 500);
    axis([0 maxvaluevol 0 inf])
    set(handles.axes_histogram, 'FontSize', 7);

    % Show intensities above threshold with a different colour.
    y = imhist(vol(vol > min(vol(:))), 500);
    x = linspace(0, 1, 500)';
    hold on
    y = y(x > threshold);
    x = x(x > threshold);
    stem(x, y, 'Marker', 'none')
    hold off
end


% _________________________________________________________________________
% --- Executes on button press in pushbutton_loadipsi.
function pushbutton_loadipsi_Callback(hObject, eventdata, handles)

global imagefolder;  % inputs
global vol;
global ipsimask;     % output

% Open UI to select the masks of the ipsilateral hemisphere.
[ipsiname, ipsifolder] = uigetfile(fullfile(imagefolder, '*.tif'),... 
    'Please select the masks of ipsilateral hemisphere (TIFF image sequence)');
ipsimaskpath = fullfile(ipsifolder, ipsiname);   

% Transform the TIFF stack into a (double) 3D matrix with only 0s and 1s.
ipsimask = stacktomatrix(ipsimaskpath);
ipsimask = double(logical(ipsimask));

% Check if the size of the image and the ipsimask is the same.
if all(size(ipsimask) == size(vol))
    % Change the 'Load' color to black.
    set(handles.pushbutton_loadipsi, 'ForegroundColor', 'k');
    
    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = sprintf('Loaded %s', ipsiname);
    newmsg = ['<HTML><b>', newmsg]; % make it bold
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);
    
    set(handles.checkbox_loadtoedit, 'BusyAction', 'queue');
    set(handles.checkbox_loadtoedit, 'Enable', 'on');
else
    % Change the 'Load' color to red.
    set(handles.pushbutton_loadipsi, 'ForegroundColor', 'r');
    
    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = 'ERROR! The ipsilateral mask has the wrong size; load again.';
    newmsg = ['<HTML><FONT color = "red">', newmsg]; % make it red
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);   
end


% _________________________________________________________________________
% --- Executes on button press in pushbutton_loadroi.
function pushbutton_loadroi_Callback(hObject, eventdata, handles)

global imagefolder;  % inputs
global vol;
global roimask;      % output
global editedvolmask;

% Open UI to select the mask.
[roiname, roifolder] = uigetfile(fullfile(imagefolder, '*.tif'),... 
    'Please select the mask of the intensity ROI (TIFF image sequence)');
roimaskpath = fullfile(roifolder, roiname);

% Transform the TIFF stack into a (double) 3D matrix with only 0s and 1s.
roimask = stacktomatrix(roimaskpath);
roimask = double(logical(roimask));

% Zero the edited mask to start editing again.
editedvolmask = zeros(2, 2, 2);

% Check if the size of the image and the roimask is the same.
if all(size(roimask) == size(vol))
    % Change the 'Load' color to black.
    set(handles.pushbutton_loadroi, 'ForegroundColor', 'k');
    
    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = sprintf('Loaded %s', roiname);
    newmsg = ['<HTML><b>', newmsg]; % make it bold
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);  
else
    % Change the 'Load' color to red.
    set(handles.pushbutton_loadroi, 'ForegroundColor', 'r');
    
    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = 'ERROR! The ROI mask has the wrong size; load again.';
    newmsg = ['<HTML><FONT color = "red">', newmsg]; % make it red
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);  
end


% _________________________________________________________________________
% --- Executes on button press in pushbutton_drawroi.
function pushbutton_drawroi_Callback(hObject, eventdata, handles)

global centralslice;  % inputs
global numofslices;
global voladjusted;
global roivertices;   % output

roivertices = zeros(50, 2, numofslices);

set(handles.pushbutton_volume, 'BusyAction', 'cancel');
set(handles.pushbutton_volume, 'Enable', 'on');
% Get the number of slices to be analysed from the text boxes.
if isempty(get(handles.text_firstslice, 'String'))
    set(handles.text_firstslice, 'BackgroundColor', 'r');
else
    set(handles.text_firstslice, 'BackgroundColor', 'w');    
    ni = str2double(get(handles.text_firstslice, 'String'));
end
if isempty(get(handles.text_lastslice, 'String'))
    set(handles.text_lastslice, 'BackgroundColor', 'r');
else
    set(handles.text_lastslice, 'BackgroundColor', 'w');    
    nf = str2double(get(handles.text_lastslice, 'String'));
end

% Enable/disable some objects.
set(handles.slider_drawmasks, 'Enable', 'off');
set(handles.slider_drawmasks, 'BusyAction', 'queue');
set(handles.slider_drawmasks, 'Visible', 'on');
set(handles.slider_editmasks, 'BusyAction', 'cancel');
set(handles.slider_editmasks, 'Visible', 'off');
set(handles.slider_outputslices, 'BusyAction', 'cancel');
set(handles.slider_outputslices, 'Visible', 'off');

set(handles.pushbutton_donedraw, 'BusyAction', 'queue');
set(handles.pushbutton_donedraw, 'Visible', 'on');
set(handles.pushbutton_canceldraw, 'BusyAction', 'queue');
set(handles.pushbutton_canceldraw, 'Visible', 'on');
set(handles.pushbutton_addregion, 'BusyAction', 'cancel');
set(handles.pushbutton_addregion, 'Visible', 'off');
set(handles.pushbutton_removeregion, 'BusyAction', 'cancel');
set(handles.pushbutton_removeregion, 'Visible', 'off')

set(handles.pushbutton_loaddata, 'BusyAction', 'cancel');
set(handles.pushbutton_loaddata, 'Enable', 'off');
set(handles.pushbutton_loadipsi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadipsi, 'Enable', 'off');
set(handles.pushbutton_loadroi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadroi, 'Enable', 'off');
set(handles.pushbutton_drawroi, 'BusyAction', 'queue');
set(handles.pushbutton_drawroi, 'Enable', 'off');
set(handles.pushbutton_volume, 'BusyAction', 'cancel');
set(handles.pushbutton_volume, 'Enable', 'off');
set(handles.pushbutton_edit, 'BusyAction', 'cancel');
set(handles.pushbutton_edit, 'Enable', 'off');

% In this case, show the central slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', centralslice);

% Set image slider's initial position, min, max and step.
% This slider will be invisible, but helpful to get current slice number.
set(handles.slider_drawmasks, 'Value', centralslice);
set(handles.slider_drawmasks, 'Min', ni);
set(handles.slider_drawmasks, 'Max', nf);
if ni == nf
    set(handles.slider_drawmasks, 'SliderStep', [1, 1]);
else
    set(handles.slider_drawmasks, 'SliderStep',...
        [1 / (nf - ni), 1 / (nf - ni)]);
end

% Show some instructions in log window listbox_log...
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg1 = 'Click the left mouse button to add points defining the';
newmsg2 = 'region of interest in the contralateral hemisphere.';
newmsg3 = 'Double click on the first point to close the polygon.';
newmsg4 = 'Skip drawing in a slice by pressing the ESCAPE key.';
newmsg5 = 'When you are done, press the ''tick'' button to save points.';
set(handles.listbox_log, 'String', [oldmsgs; newmsg1; newmsg2; newmsg3;...
    newmsg4; newmsg5]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);

% ----- DRAW -----
% Use MATLAB's roipoly function to display polygon drawing tool.
axes(handles.axes_outputimage);
[~, x, y] = roipoly(voladjusted(:, :, centralslice));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Fill roivertices with the coordinates of the polygon points.
if ~isempty(x)
    roivertices(1:length(x), 1, centralslice) = x;
    roivertices(1:length(x), 2, centralslice) = y;
end

% Show a message when drawing is done.
if ~isempty(x)
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = 'Drawing is done! Press the ''tick'' button.';
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);
end


% _________________________________________________________________________
% --- Executes on slider movement.
function slider_drawmasks_Callback(hObject, eventdata, handles)
    
global numofslices;     % inputs
global voladjusted;
global roivertices;     % output
    
% Disable unless user presses the ESCAPE button.
set(handles.slider_drawmasks, 'Enable', 'off');

% Get the current slice number from the slider.
sliderslice = round(get(hObject, 'Value'));

% Show the slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', sliderslice);

% ----- DRAW -----
% Show the original stack for user to start drawing using MATLAB's roipoly.
axes(handles.axes_outputimage);
[~, x, y] = roipoly(voladjusted(:, :, sliderslice));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Save vertices.
if ~isempty(x)
    roivertices = zeros(50, 2, numofslices);
    roivertices(1:length(x), 1, sliderslice) = x;
    roivertices(1:length(x), 2, sliderslice) = y;     
end

% Show a message in log window listbox_log.
if ~isempty(x)
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = 'Drawing is done! Press the ''tick'' button.';
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);
end


% _________________________________________________________________________
% --- Executes on button press in pushbutton_donedraw.
function pushbutton_donedraw_Callback(hObject, eventdata, handles)

global imagesize;         % inputs
global roivertices;
global editedvolmask;     % input from 'loaddata' / output to 'volume'
global analysedvolmasks;  % outputs
global roimask;

% Create masks using rodentmatrixtomask.m function.
isroiON = get(handles.pushbutton_drawroi, 'BusyAction');

if strcmp(isroiON, 'queue')      % drawing roi mask
    roimask = rodentmatrixtomask(roivertices, imagesize);    
    % Zero the edited mask to start editing again.
    editedvolmask = zeros(2, 2, 2);
else                             % editing the masks
    analysedvolmasks = editedvolmask;
end

% Enable/disable some objects.
set(handles.slider_drawmasks, 'BusyAction', 'cancel');
set(handles.slider_drawmasks, 'Visible', 'off');
set(handles.slider_editmasks, 'BusyAction', 'cancel');
set(handles.slider_editmasks, 'Visible', 'off');
set(handles.slider_outputslices, 'BusyAction', 'queue');
set(handles.slider_outputslices, 'Visible', 'on');

set(handles.pushbutton_donedraw, 'BusyAction', 'cancel');
set(handles.pushbutton_donedraw, 'Visible', 'off');
set(handles.pushbutton_canceldraw, 'BusyAction', 'cancel');
set(handles.pushbutton_canceldraw, 'Visible', 'off');
set(handles.pushbutton_addregion, 'BusyAction', 'cancel');
set(handles.pushbutton_addregion, 'Visible', 'off');
set(handles.pushbutton_removeregion, 'BusyAction', 'cancel');
set(handles.pushbutton_removeregion, 'Visible', 'off');

set(handles.pushbutton_loaddata, 'BusyAction', 'queue');
set(handles.pushbutton_loaddata, 'Enable', 'on');
set(handles.pushbutton_loadipsi, 'BusyAction', 'queue');
set(handles.pushbutton_loadipsi, 'Enable', 'on');
set(handles.pushbutton_loadroi, 'BusyAction', 'queue');
set(handles.pushbutton_loadroi, 'Enable', 'on');
set(handles.pushbutton_drawroi, 'BusyAction', 'queue');
set(handles.pushbutton_drawroi, 'Enable', 'on');
set(handles.pushbutton_volume, 'BusyAction', 'queue');
set(handles.pushbutton_volume, 'Enable', 'on');
set(handles.pushbutton_edit, 'BusyAction', 'queue');
set(handles.pushbutton_edit, 'Enable', 'on');

% Show a message in log window listbox_log.
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg = '---------- DRAWING COMPLETE ----------';
newmsg = ['<HTML><FONT color = "green">', newmsg]; % make it green
set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);


% _________________________________________________________________________
% --- Executes on button press in pushbutton_canceldraw.
function pushbutton_canceldraw_Callback(hObject, eventdata, handles)

global analysedvolmasks;  % input
global editedvolmask;     % output

% Check if user was editing the masks and undo all editing.
iseditON = get(handles.pushbutton_edit, 'BusyAction');

if strcmp(iseditON, 'queue')
    editedvolmask = analysedvolmasks;
end

% Enable/disable some objects.
set(handles.slider_drawmasks, 'BusyAction', 'cancel');
set(handles.slider_drawmasks, 'Visible', 'off');
set(handles.slider_editmasks, 'BusyAction', 'cancel');
set(handles.slider_editmasks, 'Visible', 'off');
set(handles.slider_outputslices, 'BusyAction', 'queue');
set(handles.slider_outputslices, 'Visible', 'on');

set(handles.pushbutton_donedraw, 'BusyAction', 'cancel');
set(handles.pushbutton_donedraw, 'Visible', 'off');
set(handles.pushbutton_canceldraw, 'BusyAction', 'cancel');
set(handles.pushbutton_canceldraw, 'Visible', 'off');
set(handles.pushbutton_addregion, 'BusyAction', 'cancel');
set(handles.pushbutton_addregion, 'Visible', 'off');
set(handles.pushbutton_removeregion, 'BusyAction', 'cancel');
set(handles.pushbutton_removeregion, 'Visible', 'off');

set(handles.pushbutton_loaddata, 'BusyAction', 'queue');
set(handles.pushbutton_loaddata, 'Enable', 'on');
set(handles.pushbutton_loadipsi, 'BusyAction', 'queue');
set(handles.pushbutton_loadipsi, 'Enable', 'on');
set(handles.pushbutton_loadroi, 'BusyAction', 'queue');
set(handles.pushbutton_loadroi, 'Enable', 'on');
set(handles.pushbutton_drawroi, 'BusyAction', 'queue');
set(handles.pushbutton_drawroi, 'Enable', 'on');
set(handles.pushbutton_volume, 'BusyAction', 'queue');
set(handles.pushbutton_volume, 'Enable', 'on');
set(handles.pushbutton_edit, 'BusyAction', 'queue');
set(handles.pushbutton_edit, 'Enable', 'on');
set(handles.checkbox_loadtoedit, 'BusyAction', 'queue');
set(handles.checkbox_loadtoedit, 'Enable', 'on');

% Cancel drawing by calling pressescape.m.
pressescape;

% Show a message in log window listbox_log.
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg = '---------- DRAWING CANCELLED ----------';
newmsg = ['<HTML><FONT color = "red">', newmsg]; % make it red
set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);


% ______________________________ ANALYSIS _________________________________
% _________________________________________________________________________
% --- Executes on button press in pushbutton_volume.
function pushbutton_volume_Callback(hObject, eventdata, handles)

global imagefolder;       % inputs
global ipsimask;
global loadtoeditmask;
global nametosaveas;
global editedvolmask;
global roimask;
global vol;
global voladjusted;
global analysedvolmasks;  % output
global outlinevolmasks;
global threshold;

% Get all required parameter values (xres, yres, slicethickness, 
% firstslice, lastslice, meanf, sdf). If a value is not given, make the
% corresponding GUI field red.
if isempty(get(handles.text_xres, 'String'))
    set(handles.text_xres, 'BackgroundColor', 'r');
else
    set(handles.text_xres, 'BackgroundColor', 'w');
    hpixsize = str2double(get(handles.text_xres, 'String'));
end
if isempty(get(handles.text_yres, 'String'))
    set(handles.text_yres, 'BackgroundColor', 'r');
else
    set(handles.text_yres, 'BackgroundColor', 'w');
    vpixsize = str2double(get(handles.text_yres, 'String'));
end
if isempty(get(handles.text_slicethickness, 'String'))
    set(handles.text_slicethickness, 'BackgroundColor', 'r');
else
    set(handles.text_slicethickness, 'BackgroundColor', 'w');
    slicethickness = str2double(get(handles.text_slicethickness, 'String'));
end
if isempty(get(handles.text_firstslice, 'String'))
    set(handles.text_firstslice, 'BackgroundColor', 'r');
else
    set(handles.text_firstslice, 'BackgroundColor', 'w');    
    ni = str2double(get(handles.text_firstslice, 'String'));
end
if isempty(get(handles.text_lastslice, 'String'))
    set(handles.text_lastslice, 'BackgroundColor', 'r');
else
    set(handles.text_lastslice, 'BackgroundColor', 'w');    
    nf = str2double(get(handles.text_lastslice, 'String'));
end
if isempty(get(handles.text_meanf, 'String'))
    set(handles.text_meanf, 'BackgroundColor', 'r');
else
    set(handles.text_meanf, 'BackgroundColor', 'w');    
    meanf = str2double(get(handles.text_meanf, 'String'));
end
if isempty(get(handles.text_sdf, 'String'))
    set(handles.text_sdf, 'BackgroundColor', 'r');
else
    set(handles.text_sdf, 'BackgroundColor', 'w');    
    sdf = str2double(get(handles.text_sdf, 'String'));
end

% Check if user is editing loaded lesion masks.
loadtoedit = get(handles.checkbox_loadtoedit, 'Value');

% Check if thresholding or editing of loaded lesion masks is performed.
if loadtoedit ~= 1 
    % Call estimatethreshold.m to estimate the threshold for analysis.
    threshold = estimatethreshold(vol, roimask, meanf, sdf);

    % Call rodentanalysis.m to analyse the images and get the lesion masks.
    analysedvolmasks = rodentanalysis(vol, ipsimask, ni, nf, threshold);
    
    % If the created masks are being edited, editedvolmask was generated
    % so the lesion masks should be the edited ones.
    if all(size(editedvolmask) == size(analysedvolmasks)) && ...
            all(sum(editedvolmask(:)) ~= sum(analysedvolmasks(:)))
        analysedvolmasks = editedvolmask; 
    end
else
    analysedvolmasks = loadtoeditmask;

    % If the loaded masks are being edited, editedvolmask was generated
    % so the lesion masks should be the edited ones.
    if all(size(editedvolmask) == size(analysedvolmasks)) && ...
            all(sum(editedvolmask(:)) ~= sum(analysedvolmasks(:)))
        analysedvolmasks = editedvolmask; 
    end
end

% Calculate the lesion volume and show it along with the threshold in 
% MATLAB's Command Window.
if loadtoedit ~= 1 
    disp('----------------------------');
    fprintf('Threshold        %6.5f\n', threshold);
end
disp('----------------------------');
volume = measurevolume(analysedvolmasks, hpixsize, vpixsize, slicethickness);
disp('----------------------------');

% Save masks if user want to.
saveimages = get(handles.checkbox_saveimages, 'Value');
numofslices = size(analysedvolmasks, 3);

if saveimages == 1
    for i = 1:numofslices
        analysedvolslice = analysedvolmasks(:, :, i); 
        
        if i == 1 
            imwrite(analysedvolslice, fullfile(imagefolder,...
                sprintf('%s analysed, mean x %.3f + SD x %.3f.tif',...
                nametosaveas, meanf, sdf)));
        else
            imwrite(analysedvolslice, fullfile(imagefolder,...
                sprintf('%s analysed, mean x %.3f + SD x %.3f.tif',...
                nametosaveas, meanf, sdf)), 'WriteMode', 'append');
        end 
    end
end     
    
% Set the calculated volume in the respective edit box.
set(handles.text_volume, 'String', volume);

% Create a boundary-only version of the masks.
outlinevolmasks = bwperim(analysedvolmasks, 4);

% Show the first slice of the analysed image.
showvalue = get(handles.popup_show, 'Value');
axes(handles.axes_outputimage);
if showvalue == 2  % masks only
    imshow(analysedvolmasks(:, :, ni));
else               % overlaid
    imshow(voladjusted(:, :, ni));
    red = cat(3, ones(size(voladjusted(:, :, ni))),...
        zeros(size(voladjusted(:, :, ni))),...
        zeros(size(voladjusted(:, :, ni))));
    hold on
    h = imshow(red);
    hold off
    set(h, 'AlphaData', outlinevolmasks(:, :, ni));
end
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Show the slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', ni);

% Set analysed image slider's initial position, min, max and step.
set(handles.slider_outputslices, 'Value', ni);
set(handles.slider_outputslices, 'Min', ni);
set(handles.slider_outputslices, 'Max', nf);
if ni == nf
    set(handles.slider_outputslices, 'SliderStep', [1, 1]);
else
    set(handles.slider_outputslices, 'SliderStep',...
        [1 / (nf - ni), 1 / (nf - ni)]);
end

% Output to GUI's log window.
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg = sprintf('(m*%.3f)+(SD*%.3f): %8.3f mm^3', meanf, sdf, volume);
newmsg = ['<HTML><FONT color = "blue"><b>', newmsg]; % make it bold blue
set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);

% Enable some objects.
set(handles.slider_outputslices, 'BusyAction', 'queue');
set(handles.slider_outputslices, 'Enable', 'on');
set(handles.pushbutton_edit, 'BusyAction', 'queue');
set(handles.pushbutton_edit, 'Enable', 'on');


% _________________________________________________________________________
% --- Executes on slider movement.
function slider_outputslices_Callback(hObject, eventdata, handles)

global analysedvolmasks;  % inputs
global outlinevolmasks;
global voladjusted;

% Get the current slice number from the slider.
sliderslice = round(get(hObject, 'Value'));

% Show the analysed image.
showvalue = get(handles.popup_show, 'Value');

axes(handles.axes_outputimage);
if showvalue == 2  % masks only
    imshow(analysedvolmasks(:, :, sliderslice));
else
    imshow(voladjusted(:, :, sliderslice));
    red = cat(3, ones(size(voladjusted(:, :, sliderslice))),...
        zeros(size(voladjusted(:, :, sliderslice))),...
        zeros(size(voladjusted(:, :, sliderslice))));
    hold on
    h = imshow(red);
    hold off
    set(h, 'AlphaData', outlinevolmasks(:, :, sliderslice));
end
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Show the slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', sliderslice);


% ______________________________ EDITING __________________________________
%__________________________________________________________________________
% --- Executes on button press in pushbutton_edit.
function pushbutton_edit_Callback(hObject, eventdata, handles)

global analysedvolmasks;  % inputs
global numofslices;                   % for input image axes
global outlinevolmasks;
global threshold;                     % for input image axes
global vol;                           % for input image axes
global voladjusted;
global editmask;          % outputs
global editedvolmask;
global newoutlinemask;

editedvolmask = analysedvolmasks;
newoutlinemask = outlinevolmasks;

% Get the number of slices to be analysed from the text boxes.
if isempty(get(handles.text_firstslice, 'String'))
    set(handles.text_firstslice, 'BackgroundColor', 'r');
else
    set(handles.text_firstslice, 'BackgroundColor', 'w');    
    ni = str2double(get(handles.text_firstslice, 'String'));
end
if isempty(get(handles.text_lastslice, 'String'))
    set(handles.text_lastslice, 'BackgroundColor', 'r');
else
    set(handles.text_lastslice, 'BackgroundColor', 'w');    
    nf = str2double(get(handles.text_lastslice, 'String'));
end

% Enable/disable some objects.
set(handles.slider_drawmasks, 'BusyAction', 'cancel');
set(handles.slider_drawmasks, 'Visible', 'off');
set(handles.slider_editmasks, 'Enable', 'off');
set(handles.slider_editmasks, 'BusyAction', 'queue');
set(handles.slider_editmasks, 'Visible', 'on');
set(handles.slider_outputslices, 'BusyAction', 'cancel');
set(handles.slider_outputslices, 'Visible', 'off');

set(handles.pushbutton_donedraw, 'BusyAction', 'queue');
set(handles.pushbutton_donedraw, 'Visible', 'on');
set(handles.pushbutton_canceldraw, 'BusyAction', 'queue');
set(handles.pushbutton_canceldraw, 'Visible', 'on');
set(handles.pushbutton_addregion, 'BusyAction', 'queue');
set(handles.pushbutton_addregion, 'Visible', 'on');
set(handles.pushbutton_removeregion, 'BusyAction', 'queue');
set(handles.pushbutton_removeregion, 'Visible', 'on');

set(handles.pushbutton_loaddata, 'BusyAction', 'cancel');
set(handles.pushbutton_loaddata, 'Enable', 'off');
set(handles.pushbutton_loadipsi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadipsi, 'Enable', 'off');
set(handles.pushbutton_loadroi, 'BusyAction', 'cancel');
set(handles.pushbutton_loadroi, 'Enable', 'off');
set(handles.pushbutton_drawroi, 'BusyAction', 'cancel');
set(handles.pushbutton_drawroi, 'Enable', 'off');
set(handles.pushbutton_volume, 'BusyAction', 'cancel');
set(handles.pushbutton_volume, 'Enable', 'off');
set(handles.pushbutton_edit, 'BusyAction', 'cancel');
set(handles.pushbutton_edit, 'Enable', 'off');

% Show the slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', ni);

% Set image slider's initial position, min, max and step.
% This slider will be invisible, but helpful to get current slice number.
set(handles.slider_editmasks, 'Value', ni);
set(handles.slider_editmasks, 'Min', ni);
set(handles.slider_editmasks, 'Max', nf);
if ni == nf
    set(handles.slider_editmasks, 'SliderStep', [1, 1]);
else
    set(handles.slider_editmasks, 'SliderStep',...
        [1 / (nf - ni), 1 / (nf - ni)]);
end

% ----- Changes to input image figure and slider -----
% Show the contrast adjusted image in inputimage axes.
axes(handles.axes_inputimage);
imshow(voladjusted(:, :, ni));
set(handles.axes_inputimage, 'XTick', []);
set(handles.axes_inputimage, 'YTick', []);

% Show the slice number in text_inputslicenumber.
set(handles.text_inputslicenumber, 'String',...
    sprintf('%d/%d', ni, numofslices));

% Set input image slider's initial position.
set(handles.slider_inputslices, 'Value', ni);

% Plot the histogram of individual slices of the original stack, excluding
% the minimum value just in case it is taken by many pixels.
histogrambutton = get(handles.radiobutton_slice, 'Value');
axes(handles.axes_histogram);
if histogrambutton == 1   
    slice = vol(:, :, ni);
    maxvalueslice = max(max(slice));
    imhist(slice(slice > min(slice(:))), 500);
    axis([0 maxvalueslice 0 inf])
    set(handles.axes_histogram, 'FontSize', 7);
    
    % Show intensities above threshold with a different colour.
    y = imhist(slice(slice > min(slice(:))), 500);
    x = linspace(0, 1, 500)';
    hold on
    y = y(x > threshold);
    x = x(x > threshold);
    stem(x, y, 'Marker', 'none')
    hold off
end
% ----------------------------------------------------

% Show some instructions in log window listbox_log...
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg1 = 'Click the left mouse button to add points defining an area';
newmsg2 = 'you want to edit. Double click on the first point to close';
newmsg3 = 'the polygon and click ''Add'' or ''Remove'' accordingly.';
newmsg4 = 'Skip drawing in a slice by pressing the ESCAPE key.';
newmsg5 = 'When all slices are edited, press the ''tick'' button';
newmsg6 = 'to confirm or the ''X'' button to discard changes.';
set(handles.listbox_log, 'String', [oldmsgs; newmsg1; newmsg2; newmsg3;...
    newmsg4; newmsg5; newmsg6]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);

% ----- DRAW -----
% Display segmented regions and use MATLAB's imfreehand tool to edit them.
axes(handles.axes_outputimage);
imshow(voladjusted(:, :, ni));
himage = imhandles(gca); % the handle to this image
red = cat(3, ones(size(voladjusted(:, :, ni))),...
    zeros(size(voladjusted(:, :, ni))),...
    zeros(size(voladjusted(:, :, ni))));
hold on
h = imshow(red);
hold off
set(h, 'AlphaData', newoutlinemask(:, :, ni));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Load the freehand selection tool. This is much faster than polygonal 
% selection when the axes contain more than 1 figure.
h = imfreehand('Closed', true);

% Create a mask using the handle to the imfreehand object.
if ~isempty(h)
    editmask = createMask(h, himage); % must specify which image in the figure
end


%__________________________________________________________________________
% --- Executes on button press in pushbutton_addregion.
function pushbutton_addregion_Callback(hObject, eventdata, handles)

global editmask;        % inputs
global ipsimask;
global numofslices;
global voladjusted;
global editvol;         % outputs
global editedvolmask;
global newoutlinemask;

% Get the current slice number from the slider.
sliderslice = round(get(handles.slider_editmasks, 'Value'));

% Call editmaskvolume.m to create a 3D matrix with the editing mask.
editvol = editmaskvolume(editmask, numofslices, sliderslice);

% Accept added region.
for i = 1:numofslices
    editedvolmask(:, :, i) = editedvolmask(:, :, i) | editvol(:, :, i);
    
    % Make sure it still lies into ipsimask.
    editedvolmask(:, :, i) = ...
        editedvolmask(:, :, i) & imfill(ipsimask(:, :, i), 'holes');
end

% Create a boundary only version of the masks.
newoutlinemask = bwperim(editedvolmask, 4);

% Show the edited image.
axes(handles.axes_outputimage);
imshow(voladjusted(:, :, sliderslice));
red = cat(3, ones(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))));
hold on
h = imshow(red);
hold off
set(h, 'AlphaData', newoutlinemask(:, :, sliderslice));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []); 

% Enable the slider.
set(handles.slider_editmasks, 'Enable', 'on');


%__________________________________________________________________________
% --- Executes on button press in pushbutton_removeregion.
function pushbutton_removeregion_Callback(hObject, eventdata, handles)

global editmask;        % inputs
global numofslices;
global voladjusted;
global editvol;         % outputs
global editedvolmask;
global newoutlinemask;

% Get the current slice number from the slider.
sliderslice = round(get(handles.slider_editmasks, 'Value'));

% Call editmaskvolume.m to create a 3D matrix with the editing mask.
editvol = editmaskvolume(editmask, numofslices, sliderslice);

% Accept removed region.
for i = 1:numofslices
    editedvolmask(:, :, i) = editedvolmask(:, :, i) & ~editvol(:, :, i);
end

% Create a boundary only version of the masks.
newoutlinemask = bwperim(editedvolmask, 4);

% Show the edited image.
axes(handles.axes_outputimage);
imshow(voladjusted(:, :, sliderslice));
red = cat(3, ones(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))));
hold on
h = imshow(red);
hold off
set(h, 'AlphaData', newoutlinemask(:, :, sliderslice));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []); 

% Enable the slider.
set(handles.slider_editmasks, 'Enable', 'on');


%__________________________________________________________________________
% --- Executes on slider movement.
function slider_editmasks_Callback(hObject, eventdata, handles)

global newoutlinemask;  % inputs
global numofslices;                   % for input image axes
global threshold;                     % for input image axes
global vol;                           % for input image axes
global voladjusted;
global editmask;        % output

% Disable unless user presses the ESCAPE button.
set(handles.slider_editmasks, 'Enable', 'off');

% Get the current slice number from the slider.
sliderslice = round(get(hObject, 'Value'));

% Show the slice number in text_outputslicenumber.
set(handles.text_outputslicenumber, 'String', sliderslice);

% ----- Changes to input image figure and slider -----
% Show the contrast adjusted image in inputimage axes.
axes(handles.axes_inputimage);
imshow(voladjusted(:, :, sliderslice));
set(handles.axes_inputimage, 'XTick', []);
set(handles.axes_inputimage, 'YTick', []);

% Show the slice number in text_inputslicenumber.
set(handles.text_inputslicenumber, 'String',...
    sprintf('%d/%d', sliderslice, numofslices));

% Set input image slider's position.
set(handles.slider_inputslices, 'Value', sliderslice);

% Plot the histogram of individual slices of the original stack, excluding
% the minimum value just in case it is taken by many pixels.
histogrambutton = get(handles.radiobutton_slice, 'Value');
axes(handles.axes_histogram);
if histogrambutton == 1   
    slice = vol(:, :, sliderslice);
    maxvalueslice = max(max(slice));
    imhist(slice(slice > min(slice(:))), 500);
    axis([0 maxvalueslice 0 inf])
    set(handles.axes_histogram, 'FontSize', 7);
    
    % Show intensities above threshold with a different colour.
    y = imhist(slice(slice > min(slice(:))), 500);
    x = linspace(0, 1, 500)';
    hold on
    y = y(x > threshold);
    x = x(x > threshold);
    stem(x, y, 'Marker', 'none')
    hold off
end
% ----------------------------------------------------

% ----- DRAW -----
% Display segmented regions and use MATLAB's imfreehand tool to edit them.
axes(handles.axes_outputimage);
imshow(voladjusted(:, :, sliderslice));
himage = imhandles(gca); % the handle to this image
red = cat(3, ones(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))),...
    zeros(size(voladjusted(:, :, sliderslice))));
hold on
h = imshow(red);
hold off
set(h, 'AlphaData', newoutlinemask(:, :, sliderslice));
set(handles.axes_outputimage, 'XTick', []);
set(handles.axes_outputimage, 'YTick', []);

% Load the freehand selection tool. This is much faster than polygonal 
% selection when the axes contain more than 1 figure.
h = imfreehand('Closed', true);

% Create a mask using the handle to the imfreehand object.
if ~isempty(h)
    editmask = createMask(h, himage); % must specify which image in the figure
end


%__________________________________________________________________________
% --- Executes on button press in pushbutton_loadtoedit.
function pushbutton_loadtoedit_Callback(hObject, eventdata, handles)
 
global imagefolder;     % inputs
global vol;
global loadtoeditmask;  % output

% Open UI to select the lesion masks to be edited.
[loadtoeditname, loadtoeditfolder] = uigetfile(fullfile(imagefolder, '*.tif'),... 
    'Please select the lesion masks you want to edit (TIFF image sequence)');
loadtoeditpath = fullfile(loadtoeditfolder, loadtoeditname);   

% Transform the TIFF stack into a (double) 3D matrix with only 0s and 1s.
loadtoeditmask = stacktomatrix(loadtoeditpath);
loadtoeditmask = double(logical(loadtoeditmask));

% Check if the size of the image and the loadtoeditmask is the same.
if all(size(loadtoeditmask) == size(vol))
    % Change the 'Load to edit' color to black.
    set(handles.pushbutton_loadtoedit, 'ForegroundColor', 'k');
    
    % Enable some objects.
    set(handles.pushbutton_volume, 'BusyAction', 'queue');
    set(handles.pushbutton_volume, 'Enable', 'on');
    set(handles.pushbutton_edit, 'BusyAction', 'queue');
    set(handles.pushbutton_edit, 'Enable', 'on');

    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = sprintf('Loaded %s', loadtoeditname);
    newmsg = ['<HTML><b>', newmsg]; % make it bold
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize); 
else
    % Change the 'Load to edit' color to red.
    set(handles.pushbutton_loadtoedit, 'ForegroundColor', 'r');
    
    % Output to log window listbox_log...
    oldmsgs = cellstr(get(handles.listbox_log, 'String'));
    newmsg = 'ERROR! The lesion mask has the wrong size; load again.';
    newmsg = ['<HTML><FONT color = "red">', newmsg]; % make it red
    set(handles.listbox_log, 'String', [oldmsgs; newmsg]);
    logsize = size(get(handles.listbox_log, 'String'), 1);
    set(handles.listbox_log, 'Value', logsize);   
end

% Show some instructions in log window listbox_log...
oldmsgs = cellstr(get(handles.listbox_log, 'String'));
newmsg1 = 'Press the ''Measure volume'' button to calculate the volume.';
newmsg2 = 'Then, press the ''Edit'' button to edit the lesion masks.';
set(handles.listbox_log, 'String', [oldmsgs; newmsg1; newmsg2]);
logsize = size(get(handles.listbox_log, 'String'), 1);
set(handles.listbox_log, 'Value', logsize);


%__________________________________________________________________________
% --- Executes on button press in checkbox_loadtoedit.
function checkbox_loadtoedit_Callback(hObject, eventdata, handles)
 
% Check if user is editing loaded lesion masks.
loadtoedit = get(hObject, 'Value');

% Check if thresholding or editing of loaded lesion masks is performed.
if loadtoedit == 1 
    set(handles.pushbutton_loadtoedit, 'BusyAction', 'queue');
    set(handles.pushbutton_loadtoedit, 'Enable', 'on');
else
    set(handles.pushbutton_loadtoedit, 'BusyAction', 'cancel');
    set(handles.pushbutton_loadtoedit, 'Enable', 'off');
end


% _________________________________________________________________________
% --- Executes on button press in checkbox_saveimages.
function checkbox_saveimages_Callback(hObject, eventdata, handles)


%__________________________________________________________________________
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function rodentanalysisfigure_WindowButtonUpFcn(hObject, eventdata, handles)


%__________________________________________________________________________
% --- Executes on key press with focus on rodentanalysisfigure and none of its controls.
function rodentanalysisfigure_KeyPressFcn(hObject, eventdata, handles)

% This is the only method to avoid roipoly errors in Command Window when
% drawing. The user is forced to press the ESCAPE key to continue drawing
% in the next slices, while suppressing errors at the same time.
key = get(gcf, 'CurrentKey');
if strcmp(key, 'escape')
    set(handles.slider_drawmasks, 'Enable', 'on');
    set(handles.slider_editmasks, 'Enable', 'on');
end


%__________________________________________________________________________
% --- Executes on mouse motion over figure - except title and menu.
function rodentanalysisfigure_WindowButtonMotionFcn(hObject, eventdata, handles)



% ________________________ INPUTS and TEXT BOXES __________________________
% _________________________________________________________________________
% --- Executes during object creation, after setting all properties.
function slider_inputslices_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% INDIVIDUAL BUTTONS OF A BUTTON GROUP MUST NOT BE CODED
% --- Executes during object creation, after setting all properties.
function radiobutton_stack_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function radiobutton_slice_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function slider_drawmasks_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function text_inputslicenumber_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_inputslicenumber_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outputslicenumber_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_outputslicenumber_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_log_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function listbox_log_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_xres_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_xres_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_yres_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_yres_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_slicethickness_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_slicethickness_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_firstslice_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_firstslice_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_lastslice_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_lastslice_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_meanf_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_meanf_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_sdf_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_sdf_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end  

function text_volume_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function text_volume_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_show_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function popup_show_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function slider_outputslices_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function slider_editmasks_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
