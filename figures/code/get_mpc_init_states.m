function output = get_mpc_init_states(config)
    % Get Matpower case struct for the initial states of all 3 interconnections
    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))
    if nargin < 1
        config = load_config();
    end
    output = struct();
    for i = 1 : length(config.interconn)
        file_name = strcat(config.interconn{i}, '_init_state.mat');
        output.(config.interconn{i}) = load(fullfile(config.mpc_init_state_folder, file_name), 'mpc').mpc;
    end
end