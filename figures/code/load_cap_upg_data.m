% Load the saved capacity upgrade data structure
folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))
load(fullfile(load_config().output_folder, 'cap_upg_data.mat'), 'cap_upg')
