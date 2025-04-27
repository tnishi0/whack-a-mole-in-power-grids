function fig_4_county_maps
    % Create PNG files for the figure showing 6 county maps color-code by 
    % the relative capacity increase and fraction of lines upgraded
    
    disp('--- Generating Fig 4 ---')

    tic

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))

    config = load_config();
    data_folder = fullfile(config.data_folder, 'fig_4_county_maps');
    output_folder = fullfile(config.output_folder, 'fig_4_county_maps');

    % Ensure the output folder exists
    if ~exist(output_folder, 'dir')
        mkdir(output_folder)
    end

    % Create two visualization for each upgrade strategy
    variables_to_plot = {'capacity_upgrades', 'num_upgraded_lines'};
    for i = 1 : length(config.strategies)
        strategy = config.strategies{i};
        file_name = sprintf('fig_county_maps_compute_%s.mat', strategy);

        % Load the computed relative capacity increase and fraction of lines upgraded
        % stored as part of a CountyMapCapUpg object county_map
        load(fullfile(data_folder, file_name), 'county_map')

        % Draw a map and color bar for each variable and export them to PNG files
        fprintf('%s strategy:\n', strategy);
        for j = 1 : length(variables_to_plot)
            variable_to_plot = variables_to_plot{j};
            fprintf('Plotting %s...', variable_to_plot);
            county_map.set_colors(variable_to_plot)
            file_name = sprintf('%s_%s.png', variable_to_plot, strategy);
            file_path = fullfile(output_folder, file_name);
            county_map.to_png(file_path)
            fprintf('Exported county_map to "%s"\n', file_path);
            if i == 1  % Only for the first strategy, since it is common to all strategies
                file_name = sprintf('color_bar_%s.png', variable_to_plot);
                file_path = fullfile(output_folder, file_name);
                county_map.color_bar_to_png(file_path)
                fprintf('Exported color bar to "%s"\n', file_path);
            end
        end
    end
    
    delete(county_map)
    toc
end