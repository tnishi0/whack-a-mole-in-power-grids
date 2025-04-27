function fig_4_county_maps_compute
    % Create and save a CountyMapCapUpg object for each of the 3 strategies.
    % The following data files, which are required to run this function 
    % are excluded to comply with an NDA:
    %
    %  In the folder "figures/data/counties_data":
    %  - area_counties_carto.mat
    %  - area_counties.mat
    %
    %  In the folder "figures/data/bus_geo_loc_data/":
    %  - texas_buses.csv
    %  - west_buses.csv
    %  - east_buses.csv

    tic

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))

    config = load_config();

    % For this figure we use the first failure case
    ffl = 1;

    % Load the capacity upgrade results data (creates cap_upg)
    load_cap_upg_data()

    % If set to true, the method get_num_lines will count the lines with infinite capacity
    cap_upg.count_lines_inf_cap = true;

    data_folder = fullfile(config.data_folder, 'fig_4_county_maps');
    if ~exist(data_folder, 'dir')
        mkdir(data_folder)
    end
    
    for i = 1 : length(config.strategies)
        strategy = config.strategies{i};
        message = sprintf('%s strategy:', strategy);
        timer = Timer(message, true);
        county_map = CountyMapCapUpg();
        county_map = cap_upg.add_capacity_upgrade_data(county_map, strategy, ffl);
        county_map = county_map.remove_boundary_data();
        file_name = sprintf('fig_county_maps_compute_%s.mat', strategy);
        save(fullfile(data_folder, file_name), 'county_map')
        fprintf('Saved county_map to "%s"\n', file_name)
        timer.stop()
    end
    
    delete(county_map)
    toc
end