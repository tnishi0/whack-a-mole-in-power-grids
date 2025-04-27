function ext_data_fig_9_sim_fail_based
% Generate PNG image on which Extended Data Figure 9 is based

disp('--- Generating Extended Data Fig 9 ---')

folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))

config = load_config();
data_folder = fullfile(config.data_folder, 'failure_based');
output_folder = fullfile(config.output_folder, 'ext_data_fig_9_sim_fail_based');

% Ensure the output folder exists
if ~exist(output_folder, 'dir')
    mkdir(output_folder)
end

total_num_lines = 125948;

% The threshold for determining if the vulnuerable set is "eliminated"
threshold_no_vul_set = 15;
threshold_line_y = threshold_no_vul_set / total_num_lines;

% Open the base figure
prev_ver_fig_file = fullfile(data_folder, 'base_figure.fig');
fh = openfig(prev_ver_fig_file, 'invisible');
ah = get(gcf,'Children');
set(ah,'FontSize',10);

for ffl = 0:1
    
    % Choose the correct axes
    switch ffl
        case 0
            ah0 = ah(2); % top panel
        case 1
            ah0 = ah(1); % bottom panel
    end

    % Load data
    file_name = sprintf('ffl%d_fitted_vulnerables.mat', ffl);
    s = load(fullfile(data_folder, file_name), 'x', 'fitted_vss');
    x = s.x;
    fitted_vss = s.fitted_vss; % vss = vulnerable set size
    fn = sprintf('ffl%d_number_of_unique_upgrades.mat', ffl);
    s = load(fullfile(data_folder,fn), 'nu');
    nu = s.nu;

    % Only plot up to 10^5 iterations (for the orange curves)
    ix = (x < 1e5);
    x = x(ix); fitted_vss = fitted_vss(:,ix);
    nu = nu(:,ix);

    % Update the top panel
    yyaxis(ah0,'left')
    
    % Get the individual cascade size data (plotted with black vertical bars),
    % normalize by total_num_lines, and update the blue curve
    file_name = fullfile( ...
        config.data_folder, 'failure_based', ...
        sprintf('cascade_sizes_ffl%d.mat', ffl));
    load(file_name, 'individual_cascades')
    h = get(ah0,'Children');
    set(h(1), ...
        'XData', individual_cascades.x, ...
        'YData', individual_cascades.sizes / total_num_lines)

    % Adjust the vertical axis limits and tick marks
    yl = ylim(ah0);
    yl(1) = 1e-4;
    ylim(ah0, yl)
    yticks(ah0, 10.^(-4:-1))
    stem_plt = findobj(ah0, 'Type', 'Stem');
    stem_plt.BaseLine.BaseValue = 1e-4;

    % Update the thick blue curve for the mean vulnerable set size
    % and add thin blue curves for the individual realizations
    y = mean(fitted_vss,1)/total_num_lines;
    ix = ( y > yl(1) ); % Trim the bottom of the curve
    set(h(2), 'XData', x(ix), 'YData', y(ix), 'LineWidth', 1)
    c = get(h(2), 'Color'); 
    hold(ah0,'on')
    for i = 1:size(fitted_vss,1)
        % Trim the bottom of the curve
        ix = ( fitted_vss(i,:)/total_num_lines > yl(1) );
        plot(ah0, x(ix), fitted_vss(i,ix)/total_num_lines, '-', ...
            'Color', 0.2*c + 0.8*[1,1,1], 'LineWidth', 0.5)
    end
    hold(ah0,'off')

    % Reorder the plots
    h = get(ah0,'Children');
    set(ah0,'Children',[h(22); h(1:20); h(21)]);

    % Make the left axis color black
    ah0.YAxis(1).Color = 'k';

    % Update the orange curve in the top panel
    yyaxis(ah0,'right')
    h = get(ah0,'Children');
    y = cumsum(nu,2)/total_num_lines;
    set(h, 'XData', x, 'YData', mean(y,1), 'LineWidth', 1)
    c = get(h, 'Color'); % The orange color
    hold(ah0,'on')
    plot(ah0, x, y, '-', 'Color', 0.2*c + 0.8*[1,1,1], 'LineWidth', 0.5)
    hold(ah0,'off')
    h = get(ah0,'Children');
    set(ah0,'Children',[h(21); h(1:20)]);

    % Make the right axis color black
    ah0.YAxis(2).Color = 'k';

end

% Export to PNG file.
output_file_name = sprintf('%s_export.png', mfilename);
print(fh, '-dpng', '-r300', fullfile(output_folder, output_file_name));
fprintf('Generated "%s"\n', output_file_name);

% Add the red threshold line and export to another PNG file
fprintf( ...
    'Drawing threshold line at %d / %d = %.1f x 10^(-4)\n', ...
    threshold_no_vul_set, total_num_lines, threshold_line_y / 1e-4 ...
);
for ah0 = [ah(2), ah(1)]
    yyaxis(ah0, 'left')
    xl = xlim(ah0);
    hold(ah0, 'on')
    plot(ah0, xl, threshold_line_y * [1, 1], 'r-', 'LineWidth', 0.5)
    hold(ah0, 'off')
end
output_file_name = sprintf('%s_export_threshold_line.png', mfilename);
print(fh, '-dpng', '-r300', fullfile(output_folder, output_file_name));
fprintf('Generated "%s"\n', output_file_name);

% Close the figure
close(fh);