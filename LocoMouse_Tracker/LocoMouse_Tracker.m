function varargout = LocoMouse_Tracker(varargin)
% LOCOMOUSE_TRACKER MATLAB code for LocoMouse_Tracker.fig
% The LocoMouse_Tracker GUI tracks a list of video files once it is given a
% background search method, a calibration file, a model file, an output
% folder parsing method and an output folder.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014

% Last Modified by GUIDE v2.5 03-Nov-2015 19:47:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LocoMouse_Tracker_OpeningFcn, ...
                   'gui_OutputFcn',  @LocoMouse_Tracker_OutputFcn, ...
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


% --- Executes just before LocoMouse_Tracker is made visible.
function LocoMouse_Tracker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocoMouse_Tracker (see VARARGIN)

% Choose default command line output for LocoMouse_Tracker
handles.output = hObject;

% Initialising suppoted video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2)+1;
handles.supported_files = cell(handles.N_supported_files,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';
set(handles.figure1,'UserData','');

% Getting the install path for LocoMouseTracker:
[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

% Reading background parsing modes:
bkg_list = rdir(fullfile(handles.root_path,'background_parse_functions','*.m'),'',fullfile(handles.root_path,['background_parse_functions' filesep]) );
bkg_list = strrep({bkg_list(:).name},'.m','');
if isempty(bkg_list)
    bkg_list = {''};
end
set(handles.popupmenu_background_mode,'String',bkg_list);clear bkg_list;

% Reading output parsing modes:
output_list = rdir(fullfile(handles.root_path,'output_parse_functions','*.m'),'',fullfile(handles.root_path,['output_parse_functions' filesep]));
output_list = strrep({output_list(:).name},'.m','');
if isempty(output_list)
   output_list = {''}; 
end
set(handles.popupmenu_output_mode,'String',output_list);clear output_list

% Reading calibration files:
idx_list = rdir(fullfile(handles.root_path,'calibration_files','*.mat'),'',fullfile(handles.root_path,['calibration_files' filesep]));
idx_list = strrep({idx_list(:).name},'.mat','');
if isempty(idx_list)
   idx_list = {''}; 
end
set(handles.popupmenu_calibration_files,'String',idx_list);clear idx_list

% Reading model files:
model_list = rdir(fullfile(handles.root_path,'model_files','*.mat'),'',fullfile(handles.root_path,['model_files' filesep]));
model_list = strrep({model_list(:).name},'.mat','');
if isempty(model_list)
   model_list = {' '}; 
end
set(handles.popupmenu_model,'String',model_list);clear model_list

% Initializing the output folder to the current path:
set(handles.edit_output_path,'String',pwd);
set(handles.figure1,'userdata',pwd);

% Set of handles that are disabled uppon tracking:
    handles.disable_with_start = [  handles.pushbutton_start ... 
                                    handles.pushbutton_add_background_mode ...
                                    handles.pushbutton_add_calibration_file ...
                                    handles.pushbutton_add_file ...
                                    handles.pushbutton_add_folder ...
                                    handles.pushbutton_add_model ...
                                    handles.pushbutton_add_output_mode ...
                                    handles.pushbutton_add_with_subfolders ...
                                    handles.pushbutton_browse_output ...
                                    handles.pushbutton_remove ...
                                    handles.popupmenu_background_mode ...
                                    handles.popupmenu_calibration_files ...
                                    handles.popupmenu_model ...
                                    handles.popupmenu_output_mode ...
                                    handles.edit_output_path ...
                                    handles.checkbox_overwrite_results ...
                                    handles.BoundingBox_choice ...
                                    handles.MouseOrientation ...
                                    handles.LoadSettings ...
                                    handles.SaveSettings ...
                                    ];

handles.enable_with_start = handles.pushbutton_stop;

handles.disable_while_running = get(handles.figure1,'Children');

% Making sure any ctrl+c deletes the gui to prevent further malfunctioning:
setappdata(handles.figure1,'current_search_path',pwd);

% Update handles structure
guidata(hObject, handles);

set(handles.figure1,'CloseRequestFcn',@LocoMouse_closeRequestFcn);

% Loading latest settings

    [LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
    LMT_path = [LMT_path filesep 'GUI_Settings'];
    if exist(LMT_path,'dir')==7
        if exist([LMT_path filesep 'GUI_Recovery_Settings.mat'],'file') == 2
            LoadSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat')
        end
    end

% UIWAIT makes LocoMouse_Tracker wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function LocoMouse_closeRequestFcn(hObject, eventdata)
    disp('Saving')
    handles = guidata(gcbo);
    SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat') 
    delete(gcbo)

% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_Tracker_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_files


% --- Executes during object creation, after setting all properties.
function listbox_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_add_file.
function pushbutton_add_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_search_path = getappdata(handles.figure1,'current_search_path');
[chosen_file,chosen_path] = uigetfile(handles.supported_files,'Choose supported video file',current_search_path);
chosen_fullfile = fullfile(chosen_path,chosen_file);

if ischar(chosen_file)
    setappdata(handles.figure1,'current_search_path',chosen_path);
    values = waitForProcess(handles,'off');
    % Valid file selection.
    
    % Search for repetitions:
    %%% FIXME: See how this was done in other GUIs
    
    % Try to read the file with video reader:
    try 
        vid = VideoReader(chosen_fullfile);
        drawnow;
        clear vid
        waitForProcess(handles,'on',values);
    catch
       %%% Play error sound and write error message on log box!
%        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r'); 
       fprintf('Error: Could not open %s with VideoReader!\n',chosen_fullfile);
       waitForProcess(handles,'on',values);
       return;
    end
    
    % Add file to file listbox:
    current_file_list = get(handles.listbox_files,'String');
    N_files = size(current_file_list,1);
    if N_files == 0
        handles = changeGUIEnableStatus(handles,'on');
    end
    current_file_list = cat(1,current_file_list,{chosen_fullfile});
    set(handles.listbox_files,'String',current_file_list);
    set(handles.listbox_files,'Value',length(current_file_list));
    clear current_file_list
end


% --- Executes on button press in pushbutton_add_folder.
function pushbutton_add_folder_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Valid file selection.
current_search_path = getappdata(handles.figure1,'current_search_path');
chosen_dir = uigetdir(current_search_path,'Choose directory with supported video files');
setappdata(handles.figure1,'current_search_path',current_search_path);

if ischar(chosen_dir)% Valid dir selection.
    values = waitForProcess(handles,'off');
    % List all supported video files in such dir:
    file_list = cell(handles.N_supported_files,1);
    isempty_file_type = true(1,handles.N_supported_files);
    
    for i_f = 1:handles.N_supported_files
        file_list{i_f} = getDataList(fullfile(chosen_dir,handles.supported_files{i_f}));
        isempty_file_type(i_f) = isempty(file_list{i_f});
    end
    if ~all(isempty_file_type)
        file_list = char(file_list(~isempty_file_type));
        N_candidate_files = size(file_list,1);
        kp = true(1,N_candidate_files);
        
        % Search for repetitions:
        %%% FIXME: See how this was done in other GUIs
        
        % Try to read the file with video reader:
        for i_f = 1:N_candidate_files
            file_name_f = strtrim(file_list(i_f,:));
            try
                vid = VideoReader(file_name_f);
                clear vid
                fprintf('%s added successfully.\n',file_name_f);
            catch
                %%% Play error sound and write error message on log box!
                %        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r');
                fprintf('Error: Could not open %s with VideoReader!\n',file_name_f);
                kp(i_f) = false;
            end
        end
        file_list = file_list(kp,:);
        waitForProcess(handles,'on',values);
        if ~isempty(file_list)
            % Add file to file listbox:
            current_file_list = get(handles.listbox_files,'String');
            if size(current_file_list,1) == 0
                handles = changeGUIEnableStatus(handles,'on');
            end
            
            current_file_list = cat(1,current_file_list,file_list);
            set(handles.listbox_files,'String',current_file_list);
            set(handles.listbox_files,'Value',size(current_file_list,1));
            clear current_file_list file_list
            
            
        else
            fprintf('No supported video files found!\n');
        end
    else
        fprintf('No supported video files found!\n');
    end
end
guidata(handles.figure1,handles);

% --- Executes on button press in pushbutton_add_with_subfolders.
function pushbutton_add_with_subfolders_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_with_subfolders (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chosen_dir = uigetdir('','Choose directory with supported video files');

if ischar(chosen_dir)
    file_list = cell(handles.N_supported_files,1);
    kp_f = true(handles.N_supported_files,1);
    for i_f = 1:handles.N_supported_files
        d = rdir(fullfile(chosen_dir,'**',handles.supported_files{i_f}));d = {d(:).name};
        file_list{i_f} = char(d'); clear d
        N_candidate_files = size(file_list{i_f},1);
        fprintf('%d %s files found\n',N_candidate_files,handles.supported_files{i_f});
        kp_ff = true(1,N_candidate_files);
        for i_ff = 1:N_candidate_files
            file_name_ff = strtrim(strtrim(file_list{i_f}(i_ff,:)));
            try
                vid = VideoReader(file_name_ff);
                clear vid
                fprintf('%s added successfully.\n',file_name_ff);
            catch
                %%% Play error sound and write error message on log box!
                %        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r');
                fprintf('Error: Could not open %s with VideoReader!\n',file_name_ff);
                kp_ff(i_ff) = false;
            end
        end
        file_list{i_f} = file_list{i_f}(kp_ff,:);
        if isempty(file_list{i_f})
            kp_f(i_f) = false;
        end
    end
    file_list = char(file_list(kp_f));
    current_list = get(handles.listbox_files,'String');
    if (isempty(current_list)) && (~isempty(file_list) > 0)
        handles = changeGUIEnableStatus(handles,'on'); 
    end
    set(handles.listbox_files,'String',cat(1,current_list,{file_list}));
end
guidata(handles.figure1,handles);

% --- Executes on selection change in popupmenu_output_mode.
function popupmenu_output_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_output_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_output_mode


% --- Executes during object creation, after setting all properties.
function popupmenu_output_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_background_mode.
function popupmenu_background_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_background_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_background_mode


% --- Executes during object creation, after setting all properties.
function popupmenu_background_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_log.
function listbox_log_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_log contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_log


% --- Executes during object creation, after setting all properties.
function listbox_log_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_start.
function pushbutton_start_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Geting the video file list:
disp('----------------[Tracking START]----');
SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat');

set(handles.disable_with_start,'Enable','off');
set(handles.enable_with_start,'Enable','on');
% reset_gui_state = onCleanup(@()());
drawnow;
tfile_list = get(handles.listbox_files,'String');
file_list = cell(size(tfile_list,1),1);
for tfl_i = 1:size(tfile_list,1)
    file_list{tfl_i} = strtrim(tfile_list(tfl_i,:));
end
clear('tfile_list');
Nfiles = size(file_list,1);

% Calibration file;
calibration_file_pos = get(handles.popupmenu_calibration_files,'Value');
calibration_file = get(handles.popupmenu_calibration_files,'String');calibration_file = calibration_file{calibration_file_pos};clear calibration_file_pos;
handles = loadCalibrationFile(fullfile(handles.root_path,'calibration_files',[calibration_file '.mat']),handles);clear calibration_file

% Model file:
model_file_pos = get(handles.popupmenu_model,'Value');
model_file = get(handles.popupmenu_model,'String');model_file = model_file{model_file_pos};clear model_file_pos;
handles = loadModel(fullfile(handles.root_path,'model_files',[model_file '.mat']),handles); clear model_file

% Output and background functions:
bkg_mode = get(handles.popupmenu_background_mode,'Value');
output_mode = get(handles.popupmenu_output_mode,'Value');
bkg_fun = get(handles.popupmenu_background_mode,'String');bkg_fun = bkg_fun{bkg_mode};clear bkg_mode
output_fun = get(handles.popupmenu_output_mode,'String');output_fun = output_fun{output_mode};clear output_mode

% Reading output path:
output_path = get(handles.edit_output_path,'String');
try
    if isempty(gcp('nocreate'))
        parpool('open');
    end
catch
    parpool('local');
end
drawnow;
fprintf('Processing %d video files:\n',Nfiles);
error_counter = 0;

total_time = tic;

for i_files = 1:Nfiles
    disp('----------------------');
    tic;
    % Going over the file list:
    file_name = char(strtrim(file_list{i_files}));
    [~,trial_name,~] = fileparts(file_name);
    [out_path_data,out_path_image] = feval(output_fun,output_path,file_name);
  
    data_file_name = fullfile(out_path_data,[trial_name '.mat']);
    image_file_name = fullfile(out_path_image,[trial_name '.png']);
    clear trial_name;
    
    % Check if data folder exists:
    if ~exist(out_path_data,'dir')
        mkdir(out_path_data);
    end
    % Check if image folder exists:
    if ~exist(out_path_image,'dir')
        mkdir(out_path_image);
    end
    
    if get(handles.checkbox_overwrite_results,'Value') || ...
            (~exist(data_file_name,'file') && ~exist(image_file_name,'file'))
        % If not overwriting results, checking if files exist.
        bkg_file = feval(bkg_fun,file_name);
        if isempty(bkg_file)
            bkg_file = 'compute';
        end
        
        % Attempting to track:
        try
            current_file_time = tic;
            fprintf('Tracking %s ...\n',file_name)
            handles.data.bkg = bkg_file;clear bkg_file;
            handles.data.vid = file_name;
            
%            LocoMouse_Tracker handles.data.flip = false; % added by HGM for the treadmill
            switch handles.MouseOrientation.Value
                case 2
                    handles.data.flip = 'LR';
                case 3
                    handles.data.flip = false;
                case 4
                    handles.data.flip = true;
            end
            
            [final_tracks,tracks_tail,OcclusionGrid,bounding_box,handles.data,debug] = MTF_rawdata(handles.data, handles.model, handles.BoundingBox_choice.Value);
            [final_tracks,tracks_tail] = convertTracksToUnconstrainedView(final_tracks,tracks_tail,size(handles.data.ind_warp_mapping),handles.data.ind_warp_mapping,handles.data.flip,handles.data.scale);
            % clearing the background image to avoid problems:
            
            % Saving tracking data:
            data = handles.data;
            save(data_file_name,'final_tracks','tracks_tail','OcclusionGrid','bounding_box','debug','data');
            % Performing swing and stance detection:
            clear data;

            fprintf('Done. Elapsed time: ')
            disp(datestr(datenum(0,0,0,0,0,toc(current_file_time)),'HH:MM:SS'));
        catch tracking_error
%             tracking_error
            displayErrorGui(tracking_error);
            error_counter = error_counter + 1;
        end
    else
        fprintf('%s has already been tracked. To re-track check the "Overwrite existing results" box.\n',file_name);
    end
    disp('----------------------');
	handles.data.bkg = '';
    handles.data.vid = '';
    handles.data = rmfield(handles.data,'flip');
end
fprintf('%d out of %d files correctly processed.\n',Nfiles-error_counter,Nfiles);
fprintf('Total run time: ');
disp(datestr(datenum(0,0,0,0,0,toc),'HH:MM:SS'))
disp('------------------[Tracking END]----');
set(handles.disable_with_start,'Enable','on');
set(handles.enable_with_start,'Enable','off');

% --- Executes on button press in pushbutton_stop.
function pushbutton_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.disable_with_start,'Enable','on');
set(handles.enable_with_start,'Enable','off');
guidata(handles.figure1,handles);

% --- Executes on button press in pushbutton_add_output_mode.
function pushbutton_add_output_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_background_method.
function pushbutton_add_background_method_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_overwrite_results.
function checkbox_overwrite_results_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_overwrite_results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_overwrite_results


% --------------------------------------------------------------------
function menu_menu_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_output_Callback(hObject, eventdata, handles)
% hObject    handle to menu_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_3_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_model.
function pushbutton_browse_output_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
out_path = uigetdir(get(handles.edit_output_path,'String'));
if ischar(out_path)
    set(handles.edit_output_path,'String',out_path);
end
guidata(handles.figure1,handles);

function edit_output_path_Callback(hObject, eventdata, handles)
% hObject    handle to edit_output_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_output_path as text
%        str2double(get(hObject,'String')) returns contents of edit_output_path as a double
proposed_path = get(handles.edit_output_path,'String');

if ~exist(proposed_path,'dir')
    set(handles.edit_output_path,'String',get(handles.figure1,'UserData'));
    fprintf('Output path is not a valid path!\n');
    beep;
else
    set(handles.figure1,'UserData',proposed_path);
end

guidata(handles.figure1,handles);


% --- Executes during object creation, after setting all properties.
function edit_output_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_output_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Function that loads a model file and performs a few basic checks:
function handles = loadModel(full_file_path, handles)
    model = load(full_file_path);
    % Since there is no model file type we must check we have all the right
    % fields:
    if isfield(model,'model')
        model =model.model;
    end
    ModelFieldNames      = fieldnames(model);
    ExpectedModel        = [{'line'}  {'tail'} ; ...
                            {'point'} {'paw'} ; ...
                            {'point'} {'snout'}];
                        
    failed = false;
    if ~any(ismember(ModelFieldNames,'line')) || ~any(ismember(ModelFieldNames,'point'))    
        for emt = 1:size(ExpectedModel,1)
             if any(ismember(ModelFieldNames,ExpectedModel(emt,2)))
                if any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'w')) && any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'rho'))
                     eval(['model.',char(ExpectedModel(emt,1)),'.',char(ExpectedModel(emt,2)),' = model.',char(ExpectedModel(emt,2)),';']);
                else
                     failed = true;
                end
             else
                 failed = true;
             end

        end
    end
    if failed
        error('LocoMouse_Tracker() / loadModel() :: Model file useless.')
    else
        if ~isfield(model.point.paw,'N_points')
            model.point.paw.N_points =4;
        end
        if ~isfield(model.point.snout,'N_points')
            model.point.snout.N_points =1;
        end
        handles.model =model;
    end


% --- Function that loads a calibration file and performs a few basic checks:
function handles = loadCalibrationFile(full_file_path, handles)
try
    data = load(full_file_path);
    % Since there is no model file type we must check we have all the right
    % fields:
    name_fields = {'ind_warp_mapping','inv_ind_warp_mapping','mirror_line','split_line'};
    
    tfields = fieldnames(data);
        
    for i_f = 1:size(name_fields,2)
        tfoundfield(i_f) =any(ismember(name_fields(i_f),tfields));
    end
    allfields = all(tfoundfield([1,2])) && any(tfoundfield([3 4]));
    if ~allfields
         fprintf('ERROR: Incomplete model file.')
    else
        if tfoundfield(3) && ~tfoundfield(4)
            data.split_line = data.mirror_line;
            fprintf('WARNING: Outdated fieldname "mirror_line" should be renamed to "split_line".')
            disp(full_file_path);     
        end
        if ~isfield(data,'scale')
            data.scale = 1;
        end
        handles.data = data;
        clear data;
    end
    
catch load_error
    fprintf('Error: Could not load %s with MATLAB.\nError Message:%s\n',full_file_path,load_error.message);
    beep;
end
% Setting the old or new string according to how the computations went:
% set(handles.edit_output_path,'String',get(handles.figure1,'UserData'));


% --- Executes on button press in pushbutton_remove.
function pushbutton_remove_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

current_list = get(handles.listbox_files,'String');
current_pos = get(handles.listbox_files,'Value');
current_list(current_pos,:) = [];
N_files = size(current_list,1);
if N_files  == 0
    % If list is empty disable the list and the the remove button:
    handles = changeGUIEnableStatus(handles,'off');
elseif current_pos > N_files 
    current_pos = size(current_list,1);
end
set(handles.listbox_files,'String',current_list);
set(handles.listbox_files,'Value',current_pos);
guidata(handles.figure1,handles);

% --- Enabling/Disabling the GUI properties that depend on the existence of
% at least one file on the file list.
function handles = changeGUIEnableStatus(handles,set_value)
set([handles.pushbutton_remove handles.pushbutton_start handles.listbox_files],'Enable',set_value);


% --- Executes on selection change in popupmenu_calibration_files.
function popupmenu_calibration_files_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_calibration_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_calibration_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_calibration_files


% --- Executes during object creation, after setting all properties.
function popupmenu_calibration_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_calibration_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_add_model.
function pushbutton_add_model_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[load_file, load_path] = uigetfile('*.mat','Choose MAT file with LocoMouse model');

if ischar(load_file)
    % Check if file already exists:
    list = get(handles.popupmenu_model,'String');
    [~,fname,~] = fileparts(load_file);
    already_on_list = strcmpi(fname,list);
    
    if any(already_on_list)
        N = find(already_on_list);
        set(handles.popupmenu_model,'Value',N);
        warning('%s is already on the model list!\n',fname);
    else
        file_path = fullfile(load_path, load_file);
        db_file_path = fullfile(handles.root_path,'model_files',load_file);
        succ = copyfile(file_path,db_file_path);
        if ~succ
            error('Could not copy %s to local folder!\n',file_path)
%             warning('Could not copy %s to local folder. Attempting to proceed with current location...\n');
%             list{length(list)+1} = file_path;
        else
            % Refresh the popup list: 
            list{length(list)+1} = fname;
        end
        set(handles.popupmenu_model,'String',list);
        set(handles.popupmenu_model,'Value',length(list));
    end
    guidata(handles.figure1,handles);
end

function popupmenu_model_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenu_model as text
%        str2double(get(hObject,'String')) returns contents of popupmenu_model as a double


% --- Executes during object creation, after setting all properties.
function popupmenu_model_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_add_background_mode.
function pushbutton_add_background_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_calibration_file.
function pushbutton_add_calibration_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_calibration_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[load_file, load_path] = uigetfile('*.mat','Choose MAT file with LocoMouse model');

if ischar(load_file)
    % Check if file already exists:
    list = get(handles.popupmenu_calibration_files,'String');
    [~,fname,~] = fileparts(load_file);
    already_on_list = strcmpi(fname,list);
    
    if any(already_on_list)
        N = find(already_on_list);
        set(handles.popupmenu_calibration_files,'Value',N);
        warning('%s is already on the model list!\n',fname);
    else
        file_path = fullfile(load_path, load_file);
        db_file_path = fullfile(handles.root_path,'calibration_files',load_file);
        succ = copyfile(file_path,db_file_path);
        if ~succ
            error('Could not copy %s to local folder!\n',file_path)
        else
            % Refresh the popup list: 
            list{length(list)+1} = fname;
        end
        set(handles.popupmenu_calibration_files,'String',list);
        set(handles.popupmenu_calibration_files,'Value',length(list));
    end
    handles.latest_path = load_path;
    guidata(handles.figure1,handles);
end

% --- Executes when waiting for a process to happen:
function values = waitForProcess(handles,state,values)
% handles   the handles to the objects of the gui
% state     'on' or 'off'
% Function that disables/enables a GUI during/after execution.
% values should have the

switch state
    case 'on'
        if ~exist('values','var')
            error('var must be provided if state is ''off''.');
        end
        set(handles.figure1,'Pointer','arrow');
        set(handles.disable_while_running,{'Enable'},values);
        drawnow;
    case 'off'
        values = get(handles.disable_while_running,'Enable');
        set(handles.figure1,'Pointer','watch');
        set(handles.disable_while_running,'Enable','off');
        drawnow;
    otherwise 
        error('Unknown option!');
end



% --- Executes on selection change in MouseOrientation.
function MouseOrientation_Callback(hObject, eventdata, handles)
% hObject    handle to MouseOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MouseOrientation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MouseOrientation


% --- Executes during object creation, after setting all properties.
function MouseOrientation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MouseOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in BoundingBox_choice.
function BoundingBox_choice_Callback(hObject, eventdata, handles)
% hObject    handle to BoundingBox_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BoundingBox_choice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BoundingBox_choice


% --- Executes during object creation, after setting all properties.
function BoundingBox_choice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BoundingBox_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

[p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox'));
if isempty(p_boundingBoxFunctions)
    error('INITIALIZATION ERROR: computeMouseBox.m is missing.')
end
load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_option');
set(hObject,'String',ComputeMouseBox_option); 

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in SaveSettings.
function SaveSettings_Callback(hObject, eventdata, handles, tsfilename)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')~=7
    mkdir(LMT_path);
end

if exist('tsfilename')== 1 
    S_filename = tsfilename;
else
    S_filename = uiputfile([LMT_path filesep '*.mat']);
end

if ischar(S_filename)
    t_values.BoundingBox_choice.Value               = handles.BoundingBox_choice.Value;
    t_values.MouseOrientation.Value                 = handles.MouseOrientation.Value;
    t_values.popupmenu_model.Value                  = handles.popupmenu_model.Value;
    t_values.popupmenu_calibration_files.Value      = handles.popupmenu_calibration_files.Value;
    t_values.checkbox_overwrite_results.Value       = handles.checkbox_overwrite_results.Value;
    t_values.popupmenu_background_mode.Value        = handles.popupmenu_background_mode.Value;
    t_values.popupmenu_output_mode.Value            = handles.popupmenu_output_mode.Value;

    save([LMT_path filesep S_filename],'t_values')
    if exist([LMT_path filesep S_filename],'file')== 2
        disp('Settings saved.')
    end
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over SaveSettings.
function SaveSettings_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LoadSettings.
function LoadSettings_Callback(hObject, eventdata, handles, tlfilename)
% hObject    handle to LoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')~=7
    mkdir(LMT_path);
end

if exist('tlfilename')== 1 
    L_filename = tlfilename;
else
    L_filename = uigetfile([LMT_path filesep '*.mat']);
end

if ischar(L_filename)
    load([LMT_path filesep L_filename],'t_values');

    tfigObj = fieldnames(t_values);

    for tf = 1:size(tfigObj,1)
        set(handles.(tfigObj{tf}),'Value',t_values.(tfigObj{tf}).Value);
    end
end

