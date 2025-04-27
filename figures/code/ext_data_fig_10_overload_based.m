function ext_data_fig_10_overload_based
% Make plots and fit curves to the resampling results for Ext Data Fig 10

    disp('--- Generating Extended Data Fig 10 ---')

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))

    config = load_config();
    data_folder = fullfile(config.data_folder, 'ext_data_fig_10_overload_based');
    output_folder = fullfile(config.output_folder, 'ext_data_fig_10_overload_based');
    data_file_name = 'overload_based_compute.mat';
    output_file_name = [mfilename, '_export.pdf'];
    log_file_name = [mfilename, '_log.txt'];

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

    % Create figure/axes
    w = 6.5; h = 2.7;
    fig = figure( ...
        'PaperSize', [w, h], 'PaperPosition', [0, 0, w, h], ...
        'Visible', 'off', 'Position', [300, 300, 923, 344] ...
    );
    ax_num_upg_lines = subplot(1,2,1);
    ax_total_cap_upg = subplot(1,2,2);
    ax = [ax_num_upg_lines, ax_total_cap_upg];

    % % Load the capacity upgrade data in "cap_upg"
    % load_cap_upg_data()
        
    % Load the results
    data_file = fullfile(data_folder, data_file_name);
    results = load(data_file);

    % Remove the first data point (since the point (0, 0) does not look like a natural
    % continuation of the curve; there may be a genuine discontinuity at that point)
    results.num_samples_per_line_values(1) = [];

    % Plot the results for all 3 interconnections (the dots)
    num_upg_lines = 0;
    total_cap_upg = 0;
    for j = 1 : length(config.interconn)
        interconn = config.interconn{j};

        % Remove the first data points (as explained above)
        results.(interconn).num_upg_lines(:, 1) = [];
        results.(interconn).total_cap_upg(:, 1) = [];

        % Plot (the average of) the data points from the resampling calculations, normalizing
        % by the numbers for the whole system (not for the interconnection)
        mean_num_upg_lines = mean(results.(interconn).num_upg_lines, 1);
        mean_total_cap_upg = mean(results.(interconn).total_cap_upg, 1);
        plot( ...
            ax_num_upg_lines, ...
            results.num_samples_per_line_values, ...
            ... % mean_num_upg_lines / cap_upg.get_num_lines(), ... % normalizing by the number for the whole system
            mean_num_upg_lines / results.total_num_lines, ... % normalizing by the number for the whole system
            '.', 'MarkerSize', 8 ...
        )
        plot( ...
            ax_total_cap_upg, ...
            results.num_samples_per_line_values, ...
            ... %mean_total_cap_upg / cap_upg.get_total_initial_capacities(), ... % normalizing by the number for the whole system
            mean_total_cap_upg / results.total_capacity, ... % normalizing by the number for the whole system
            '.', 'MarkerSize', 8 ...
        )

        % num_upg_lines and total_cap_upg are the *averages* for the whole system (even though 
        % the name does not suggest it)
        num_upg_lines = num_upg_lines + mean_num_upg_lines;
        total_cap_upg = total_cap_upg + mean_total_cap_upg;

        hold(ax_num_upg_lines,'on')
        hold(ax_total_cap_upg,'on')
    end

    % Plot data points for the accumulated values for the whole system
    plot( ...
        ax_num_upg_lines, ...
        results.num_samples_per_line_values, ...
        ... %num_upg_lines / cap_upg.get_num_lines(), ... % normalizing by the number for the whole system
        num_upg_lines / results.total_num_lines, ... % normalizing by the number for the whole system
        '.', 'MarkerSize', 12 ...
    )
    plot( ...
        ax_total_cap_upg, ...
        results.num_samples_per_line_values, ...
        ... %total_cap_upg / cap_upg.get_total_initial_capacities(), ... % normalizing by the number for the whole system
        total_cap_upg / results.total_capacity, ... % normalizing by the number for the whole system
        '.', 'MarkerSize', 12 ...
    )

    if license('test','Curve_Fitting_Toolbox')
        % Configuration for the curve fitting. The variable x here correponds to
        % num_samples_per_line_values. Note that fit_equation here has a negative sign before "c". 
        % Also, the coefficient "b" in the figure caption of the paper is "a-b" here (but no need to 
        % mention its value in the paper).
        x = linspace(0, 200, 1000);
        fit_equation = 'a-(a-b)*exp(-c*x)';
        fit_method = 'NonlinearLeastSquares';
        fit_options = fitoptions('Method', fit_method);
        fprintf('Fitting a curve of the form %s using %s\n', fit_equation, fit_method);

        % Fit a curve and plot it for the number of upgraded lines. The StartPoint was hand-selected
        % based roughly on the fitted values from the previous calculation.
        disp('Number of upgraded lines:')
        fit_options.StartPoint = [6000, 3000, 0.01];
        fit_type = fittype(fit_equation, 'options', fit_options);
        [fit_obj, goodness_of_fit] = fit( ...
            results.num_samples_per_line_values', num_upg_lines', fit_type ...
        ); % num_upg_lines is the *average* over M realizations (despite the variable name)
        fprintf(' R^2 = %.6f\n', goodness_of_fit.rsquare);
        plot(ax_num_upg_lines, x, fit_obj(x) / results.total_num_lines, 'k-', 'LineWidth', 1)
        plot(ax_num_upg_lines, x, fit_obj.a * ones(size(x)) / results.total_num_lines, 'k--', 'LineWidth', 1)
        fprintf( ...
            ' Estimate of N^{upg}: %.0f lines (%.1f%%)\n', ...
            fit_obj.a, fit_obj.a / results.total_num_lines * 100 ...
        ); % The coefficient "a" is the extrapolated asymptotic value of num_upg_lines

        % Fit a curve and plot it for the total capacity upgrade. The StartPoint was hand-selected
        % based roughly on the fitted values from the previous calculation.
        disp('Total capacity upgrade:')
        fit_options.StartPoint = [4e5, 2e5, 0.01];
        fit_type = fittype(fit_equation, 'options', fit_options);
        [fit_obj, goodness_of_fit] = fit( ...
            results.num_samples_per_line_values', total_cap_upg', fit_type ...
        ); % total_cap_upg is the *average* over M realizations (despite the variable name)
        fprintf(' R^2 = %.6f\n', goodness_of_fit.rsquare);
        total_cap = results.total_capacity;
        plot(ax_total_cap_upg, x, fit_obj(x) / total_cap, 'k-', 'LineWidth', 1)
        plot(ax_total_cap_upg, x, fit_obj.a * ones(size(x)) / total_cap, 'k--', 'LineWidth', 1)
        fprintf( ...
            ' Estimate of C^{upg}: %.2f x 10^6 MVA (%.1f%%)\n', ...
            fit_obj.a / 1e6, fit_obj.a / total_cap * 100 ...
        ); % The coefficient "a" is the extrapolated asymptotic value of total_cap_upg
    end
    
    hold(ax_num_upg_lines,'off')
    hold(ax_total_cap_upg,'off');

    % Add labels and adjust axes
    legend(ax_total_cap_upg, 'Texas', 'West', 'East', 'Total', 'location', 'southeast')
    set(ax, 'FontSize', 9)
    x_range = [0, 200];
    x_label_text = '#perturbations/#branches';
    xlim(ax_num_upg_lines, x_range)
    xlabel(ax_num_upg_lines, x_label_text)
    ylim(ax_num_upg_lines, [0, 0.05])
    ylabel(ax_num_upg_lines, '#branches upgraded')
    xlim(ax_total_cap_upg, x_range)
    xlabel(ax_total_cap_upg, x_label_text)
    ylim(ax_total_cap_upg, [0, 0.01])
    ylabel(ax_total_cap_upg, 'total capacity upgrade')
    
    % Export to a file
    output_file = fullfile(output_folder, output_file_name);
    print(fig, '-dpdf', output_file)
    fprintf('Plots exported to "%s"\n', output_file_name);

    close(fig)
    diary('off')
end
