function fig_2_texas_grid_example
    % Create Fig. 2, Texas county map showing an example of whack-a-mole effect in the Texas power grid (ERCOT)

    disp('--- Generating Fig 2 ---')

    folder_path = fileparts(which(mfilename)); 
    addpath(fullfile(folder_path, '../../library'))
    
    config = load_config();
    data_folder = config.ercot_data_foler;
    output_folder = fullfile(config.output_folder, 'fig_2_texas_grid_example');
    output_file = fullfile(output_folder, 'figure.png');
    rel_Ps_file = fullfile(data_folder, 'blackout_data.mat');
    node_location_data_file = fullfile(data_folder, 'node_location_data.mat');
    ercot_boundary_data_file = fullfile(config.ercot_data_foler, 'ercot_boundary_data.mat');
    cascade_data_file = fullfile(data_folder, 'texas_cascade_data.mat');
    
    % Ensure the output folder exists
    if ~exist(output_folder, 'dir')
        mkdir(output_folder)
    end

    % Load data
    load(rel_Ps_file, ...
        'ix_tx', ...
        'xr_before', 'yr_before', 'rel_Ps_before', ...
        'xr_after', 'yr_after', 'rel_Ps_after');
    load(node_location_data_file, 'busLonLat')
    load(cascade_data_file, ...
        'xp_after', 'xp_before', 'xt_after', 'xt_before', ...
        'yp_after', 'yp_before', 'yt_after', 'yt_before', ...
        'xp_intersect', 'yp_intersect' ...
    )    
    s = load(ercot_boundary_data_file, 'boundary');
    texas = s.boundary;
    lon_tx = texas.Lon(1:end-1);
    lat_tx = texas.Lat(1:end-1);
    fh = figure('Visible', 'off', 'Position', [0 0 1281 458], ...
        'Color', 'w');
    subplot(121)
    plot_rel_Ps(xr_before, yr_before, rel_Ps_before, ix_tx, lon_tx, lat_tx)    
    hold on
    h = plot_primary_failures(xp_before, yp_before, xt_before, yt_before);
    h.Marker = '.'; h.MarkerSize = h.LineWidth;
    h.Color = [240 178 0]/255;
    hold off
    set(gca, 'Position', [-0.02 0 0.5 1])
    subplot(122)
    plot_rel_Ps(xr_after, yr_after, rel_Ps_after, ix_tx, lon_tx, lat_tx)
    hold on
    h = plot_primary_failures(xp_after, yp_after, xt_after, yt_after);
    h.Marker = '.'; h.MarkerSize = h.LineWidth;
    h = plot_primary_failures(xp_intersect, yp_intersect, [], []);
    h.Marker = '.'; h.MarkerSize = h.LineWidth;
    h.Color = [240 178 0]/255;
    hold off
    h = colorbar;
    h.FontSize = 20;
    set(gca, 'Position', [0.46 0 0.5 1])
    h.Position(1) = 0.95;
    h.Position(2) = 0.1;
    h.Position(4) = 0.8;
    c1 = [0 0 0];
    c2 = [107 107 255]/255;
    s = linspace(0,1,100)';
    colormap(s*c1+(1-s)*c2);
    saveas(gcf, output_file)
    fprintf('Output written to "%s"\n', output_file);
    close(fh)
end

function plot_rel_Ps(xr, yr, rel_Ps, ix_tx, lon_tx, lat_tx)
    im = imagesc(xr, yr, rel_Ps*100, [0 50]); % clim = [0 50] here maps rel_Ps*100 >= 50 (%) to the last color in the colormap (i.e., black)
    im.AlphaData = double(ix_tx);
    hold on
    patch(lon_tx, lat_tx, [.7 .7 .7], 'FaceAlpha', 0, 'EdgeColor', 'k', ...
        'EdgeAlpha', 1)
    hold off
    axis xy equal tight off
    set(gca, 'FontSize', 16)
end

function [h_pfs, h_trig] = plot_primary_failures(xp, yp, xt, yt)
    h_pfs = line(xp, yp, 'Color', 'r', 'LineWidth', 3, 'LineStyle', '-');
    hold on
    h_trig = line(xt, yt, ...
        'Color', [240 178 0]/255, 'LineWidth', 3, 'LineStyle', '-', ...
        'Marker', '.', 'MarkerSize', 20);
    hold off
end
