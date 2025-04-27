function create_cap_upg_data(config)
    % Create the capacity upgrade data structure and save to the output folder

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))
    addpath(fullfile(folder_path, '../../library/cascade_model'))
    addpath(fullfile(folder_path, '../../library/matpower6.0'))
    if nargin < 1
        config = load_config();
    end
    dt0 = datetime;
    fprintf('Start: %s\n', dt0);
    cap_upg = CapacityUpgradeDataStructure(config);
    cap_upg = cap_upg.load_data('frequency_based');
    cap_upg = cap_upg.load_data('failure_based');
    cap_upg = cap_upg.load_data('overload_based');
    output_file = fullfile(config.output_folder, 'cap_upg_data.mat');
    save(output_file, 'cap_upg')
    fprintf('Finished: %s\n', datetime);
    fprintf('Duration: %s\n', datetime - dt0);
end