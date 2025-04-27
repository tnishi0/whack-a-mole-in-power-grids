function ext_data_fig_10_overload_based_compute(poolobj)
    % Resample num_samples_per_line_values * num_lines_interconn perturbation from the 
    % computation for the overload-based strategy and calculate the average number of upgrapded
    % lines and total capacity upgrade over M realizations of resampling. Then fit an 
    % exponentially saturating function to extrapolate and estimate the asymptotic values of 
    % these two quantities. This calculation is for Extended Data Fig. 10. Must pass a parallel 
    % pool object poolobj.

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))

    mustBeA(poolobj, 'parallel.Pool')
    start_datetime = datetime;
    config = load_config();
    output_folder = fullfile(config.data_folder, 'ext_data_fig_10_overload_based');
    output_file_name = 'overload_based_compute.mat';
    log_file_name = 'overload_based_compute_log.txt';
    
    % Ensure the output folder exists
    if ~exist(output_folder, 'dir')
        mkdir(output_folder)
    end
    
    % Set up the log file
    log_file = fullfile(output_folder, log_file_name);
    if exist(log_file, 'file')
        delete(log_file)
    end
    diary(log_file)
    fprintf('=== %s ===\n', mfilename);
    fprintf('Start date/time: %s\n', start_datetime);

    % For reproducibility
    random_seed = 100;
    rng(random_seed)

    % Simulation parameters
    M = 100; % Number of realizations of the re-sampling process
    num_samples_per_line_values = 0:4:80; % Values for the number of samples per line (in the interconnection)
    num_points = length(num_samples_per_line_values); % Number of points that will be plotted in the figure
    results = struct( ...
        'M', M, ...
        'random_seed', random_seed, ...
        'num_samples_per_line_values', num_samples_per_line_values ...
    );

    % Load the capacity upgrade data in "cap_upg"
    load_cap_upg_data()

    % Loop through the 3 interconnections and calculate the number of upgraded lines
    % and the total capacity upgrade as functions of the number of perturbation samples per line
    results.total_num_lines = 0;
    results.total_capacity = 0;
    for j = 1 : length(config.interconn)
        interconn = config.interconn{j};
        num_lines_interconn = cap_upg.get_num_lines(interconn);
        total_capacity_interconn = cap_upg.get_total_initial_capacities(interconn);
        fprintf('For the %s interconnection:\n', interconn);

        % Read and process the raw simulation results files for the overload-based strategy from Deniz
        data_folder = config.overload_based_results_folder;
        data_file_names = config.data_source_paths.overload_based.(interconn);
        cases = {};
        t0 = datetime;
        for i = 1 : length(data_file_names)
            data_file = fullfile(data_folder, data_file_names{i});
            fprintf(' Loading "%s"...\n', data_file_names{i});
            s = load(data_file, 'cases');
            cases = cat(1, cases, s.cases);
        end
        fprintf( ...
            ' Loaded the results for %d perturbations [elapsed time: %s]\n', ...
            length(cases), datetime - t0 ...
        );

        % Prepare variables
        num_upg_lines = nan(M, num_points);
        total_cap_upg = nan(M, num_points);
        elapsed_times = repmat(duration, [1, num_points]);

        % For num_samples_per_line = 0 (Note: this turned out to be unnecessary; I removed this from the plots)
        num_upg_lines(:, 1) = 0;
        total_cap_upg(:, 1) = 0;

        % Resample for each value of the number of samples per line and calculate the number of 
        % upgraded lines and the total capacity upgrade
        for i = 2 : num_points
            t0 = datetime;
            num_samples_per_line = num_samples_per_line_values(i);
            num_samples = num_samples_per_line * num_lines_interconn;
            
            % Loop through (in parallel) M realizations of the re-sampling process
            parfor m = 1:M
                % The the re-sampling process. Sampling is done *with* replacement. With the code
                % below (with accumarry()), there is no minimum threshold for the overload amount 
                % for a line to be counted as "upgraded line" (and the overload amount to be used
                % for calculating the maximum overload).
                idx = randi(length(cases), num_samples, 1);
                line_idx_to_overload = cell2mat(cases(idx));
                line_idx_list = line_idx_to_overload(:, 1);
                overloads_list = line_idx_to_overload(:, 2);
                num_upg_lines(m, i) = sum(accumarray(line_idx_list, 1, [], @max));
                total_cap_upg(m, i) = sum(accumarray(line_idx_list, overloads_list, [], @max));
            end

            elapsed_times(i) = datetime - t0;
            fprintf( ...
                ' i = %d/%d: %d samples (%d per line) --> %.1f upgraded lines (%.1f%%), %.6f x 10^6 MVA (%.2f%%) [elapsed time: %s]\n', ...
                i, length(num_samples_per_line_values), ...
                num_samples, num_samples_per_line, ...
                mean(num_upg_lines(:, i)), ...
                mean(num_upg_lines(:, i)) / num_lines_interconn * 100, ...
                mean(total_cap_upg(:, i)) / 1e6, ...
                mean(total_cap_upg(:, i)) / total_capacity_interconn * 100, ...
                elapsed_times(i) ...
            );
        end

        results.total_num_lines = results.total_num_lines + num_lines_interconn;
        results.total_capacity = results.total_capacity + total_capacity_interconn;
        results.(interconn).num_upg_lines = num_upg_lines;
        results.(interconn).total_cap_upg = total_cap_upg;
        results.(interconn).elapsed_times = elapsed_times;    
    end

    total_elapsed_time = datetime - start_datetime;
    results.total_elapsed_time = total_elapsed_time;

    % Save the results
    output_file = fullfile(output_folder, output_file_name);
    save(output_file, '-struct', 'results')
    fprintf('Saved results to "%s"\n', output_file_name);
    fprintf('End date/time: %s\n', datetime);
    fprintf('Total elapsed time: %s\n', total_elapsed_time);
    
    diary('off')
end