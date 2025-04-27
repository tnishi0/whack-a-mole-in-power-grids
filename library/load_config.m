function config = load_config()
    % Load parameter configuration to be used

    % Names of the 3 strategies we consdier
    config.strategies = { ...
        'frequency_based', 'failure_based', 'overload_based' ...
    };

    % The 2 cases we consider: ffl = 0: all failure, ffl = 1: first failure
    config.ffl = [0, 1];
    config.ffl_folders = dictionary(0, 'ffl0', 1, 'ffl1');

    % The 3 interconnections of the US power grid network
    config.interconn = {'texas', 'west', 'east'};

    % Folder locations
    % config.current_folder = pwd;
    config.current_folder = fileparts(which(mfilename)); 
    config.figures_folder = fullfile(config.current_folder, '../figures');
    config.data_folder = fullfile(config.figures_folder, 'data');
    config.geo_loc_data_folder = fullfile( ...
        config.data_folder, 'bus_geo_loc_data' ...
    );
    config.raw_simulation_data_folder = fullfile( ...
        config.data_folder, 'raw_simulation_data' ...
    );
    config.output_folder = fullfile(config.figures_folder, 'output');
    config.mpc_init_state_folder = fullfile( ...
        config.output_folder, 'mpc_init_state' ...
    );
    config.frequency_based_results_folder = fullfile( ...
        config.data_folder, 'frequency_based' ...
    );
    for i = 1 : length(config.ffl)
        ffl = config.ffl_folders(config.ffl(i));
        config.failure_based_results_folder.(ffl) = fullfile( ...
            config.data_folder, 'failure_based', 'data_processing', ...
            ffl, '5-find_capacity_profiles', 'results' ...
        );
    end
    config.overload_based_results_folder = fullfile( ...
        config.data_folder, 'overload_based' ...
    );

    % === Simulation results data files for the frequency-based strategy ===
    % All failure case (star symbol in Ext Data Fig 7c; m = 4, k = 5)
    config.data_source_paths.frequency_based.ffl0.m = 4;
    config.data_source_paths.frequency_based.ffl0.k = 5;
    config.data_source_paths.frequency_based.ffl0.texas = ...
        'texas_ffl0_K10000_NofInc10_demandRatio1.2_capRatio1_threshold04_seed01.mat';
    config.data_source_paths.frequency_based.ffl0.west = ...
        'west_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat';
    config.data_source_paths.frequency_based.ffl0.east = { ...
        'east_trigReg-FRCC_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
        'east_trigReg-MRO_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
        'east_trigReg-NPCC_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
        'east_trigReg-RFC_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
        'east_trigReg-SERC_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
        'east_trigReg-SPP_ffl0_K10000_NofInc10_demandRatio1_capRatio1_threshold04_seed01.mat'
    };  
    % First failure case (star symbol in Ext Data Fig 7f; m = 6, k = 1)
    config.data_source_paths.frequency_based.ffl1.m = 6;
    config.data_source_paths.frequency_based.ffl1.k = 1;
    config.data_source_paths.frequency_based.ffl1.texas = ...
        'texas_ffl1_K10000_NofInc10_demandRatio1.2_capRatio1_threshold00_seed01.mat';
    config.data_source_paths.frequency_based.ffl1.west = ...
        'west_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat';
    config.data_source_paths.frequency_based.ffl1.east = { ...
        'east_trigReg-FRCC_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
        'east_trigReg-MRO_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
        'east_trigReg-NPCC_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
        'east_trigReg-RFC_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
        'east_trigReg-SERC_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
        'east_trigReg-SPP_ffl1_K10000_NofInc10_demandRatio1_capRatio1_threshold00_seed01.mat'
    };

    % === Simulation results data files for the failure-based strategy ===
    for i = 1 : length(config.ffl)
        ffl = config.ffl(i);
        ffl_folder = config.ffl_folders(ffl);
        for j = 1: length(config.interconn)
            interconn = config.interconn{j};
            config.data_source_paths.failure_based.(ffl_folder).(interconn) ...
                = sprintf('%s_%s_caps_profile.mat', interconn, ffl_folder);
        end
    end

    % === Simulation results data files for the overload-based strategy ===
    config.data_source_paths.overload_based.texas = {
        'texas_ol_profile_K4000000.mat'
        'texas_ol_profile_K4000000_seed3.mat'
    };
    config.data_source_paths.overload_based.west = {
        'west_ol_profile_K4000000_seed1.mat'
        'west_ol_profile_K4000000_seed2.mat'
    };
    config.data_source_paths.overload_based.east = {
        'east_ol_profile_K2000000_seed1.mat'
        'east_ol_profile_K6000000_seed2.mat'
    };

    % Data folder related to the Texas grid (ERCOT)
    config.ercot_data_foler = fullfile(config.data_folder, 'texas_grid_example_data');
    config.non_ercot_texas_counties_file = fullfile(config.ercot_data_foler, 'non_ercot_texas_counties.txt');
end
