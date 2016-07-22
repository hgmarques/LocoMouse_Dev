function [final_tracks_c, tracks_tail_c,OcclusionGrid,bounding_box,data,debug] = locomouse_tracker_cpp_wrapper(data,root_path, model, calib, flip, model_file, calibration_file, cpp_exec, config_file)
% Reads the inputs in the MATLAB format for LocoMouse_Tracker and parses
% them to be used for the C++ code.
[~,model_file_name,~] = fileparts(model_file);
[~,calibration_file_name,~] = fileparts(calibration_file);

model_file_yml = fullfile(root_path,'model_files',[model_file_name,'.yml']);
calibration_file_yml = fullfile(root_path,'calibration_files',[calibration_file_name,'.yml']);

if ~exist(model_file_yml,'file')
    exportLocoMouseModelToOpenCV(model_file_yml,model);
end

if ~exist(calibration_file_yml,'file')
    exportLocoMouseCalibToOpenCV(calibration_file_yml,calib);
end

char_flip = 'R';
if ischar(flip)
        if strcmpi('LR',flip) % check if mouse comes from L or R based file name [GF]
            char_flip =  data.vid(end-4);
        end  
elseif flip
    char_flip = 'L';
end

% Running CPP code
result = system(sprintf('"%s" "%s" "%s" "%s" "%s" "%s" %s',cpp_exec,config_file,data.vid,data.bkg,model_file_yml,calibration_file_yml,char_flip));
if result < 0
    error('Cpp code failed!');
end
[~,vid_name,~] = fileparts(data.vid);
output_file = sprintf('output_%s.yml',vid_name);
output = readOpenCVYAML(output_file);
delete(output_file);
final_tracks_c = permute(cat(3,output.paw_tracks0,output.paw_tracks1,output.paw_tracks2,output.paw_tracks3,output.snout_tracks0),[2 3 1]);
final_tracks_c(final_tracks_c(:)<0) = NaN;
final_tracks_c = final_tracks_c + 1;
tracks_tail_c = NaN(3,1,size(final_tracks_c,3));
OcclusionGrid = [];
bounding_box = [];
%data = []; Need to adapt the export function to output all the relevant
%parameters.
debug = [];