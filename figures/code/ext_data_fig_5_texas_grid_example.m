function ext_data_fig_5_texas_grid_example
% Create panels of Extended Data Fig 5

disp('--- Generating Extended Data Fig 5 ---')

folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))

tic

config = load_config();
data_folder = config.ercot_data_foler;
data_file = fullfile(data_folder, 'details.mat');
data_file_2 = fullfile(data_folder, 'details_2.mat');
output_folder = fullfile(config.output_folder, 'ext_data_fig_5_texas_grid_example');

% Ensure the output folder exists
if ~exist(output_folder, 'dir')
    mkdir(output_folder)
end

% snapshots to plot for panels a-h and j
ix_plot = [3, 4, 6, 37, 40, 49, 60, 208];

% x and y limits
xl = [0 9396];
yl = [0 4];

% color of bars for lines that are not overloaded
nl_color = 0.5*[1,1,1];

% color of bars for overloaded lines
ol_color = [237,198,0]/255;

fh1 = figure('Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [40 300 680 240], 'Visible', 'off');
fh2 = figure('Color', 'w', 'InvertHardcopy', 'off', ...
    'Position', [40 300 680 240], 'Visible', 'off');
h(1) = axes(fh1);
h(2) = axes(fh2);

% Load data
s = load(data_file);

% Random shuffling of indices
rng(73250)
n = size(s.rel_load_before{1},1);
ri = randperm(n);

% This corresponds to Line #8720
ix2 = 7667;

for k = 1:length(ix_plot)
    
    i = ix_plot(k);
    fprintf('i = %d:\n', i);
    
    % plot rel_load_before
    if i <= length(s.pf_before) + 1
        cla(h(1))
        bar(h(1), ri, s.rel_load_before{i}, 1, ...
            'FaceColor', nl_color, 'EdgeColor', nl_color)
        ix = ( s.rel_load_before{i} > 1 );
        rel_load_before_2 = - ones(size(s.rel_load_before{i}));
        rel_load_before_2(ix) = s.rel_load_before{i}(ix);
        hold(h(1), 'on')
        bar(h(1), ri, rel_load_before_2, 1, ...
            'FaceColor', ol_color, 'EdgeColor', ol_color, ...
            'LineWidth', 1.5, 'BaseValue', -1)
        plot(h(1), ri(ix2)*[1 1], [0, s.rel_load_before{i}(ix2)], ...
            '-', 'Linewidth', 2.5, 'Color', [0 0.8 0]);
        if i <= length(s.pf_before)
            ix_end = s.pf_before(i);
            plot(h(1), ri(ix_end)*[1 1], [0, s.rel_load_before{i}(ix_end)], ...
                'r-', 'Linewidth', 3);
        end
        ix = s.pf_before(1:i-1);
        plot(h(1), ri(ix), zeros(size(ix)), 'r.', 'MarkerSize', 15);
        plot(h(1), xl, [1 1], 'k--')
        hold(h(1), 'off')
    end
    
    % plot rel_load_after
    if i <= length(s.pf_after) + 1
        cla(h(2))
        bar(h(2), ri, s.rel_load_after{i}, 1, ...
            'FaceColor', nl_color, 'EdgeColor', nl_color)
        ix = ( s.rel_load_after{i} > 1 );
        rel_load_after_2 = - ones(size(s.rel_load_after{i}));
        rel_load_after_2(ix) = s.rel_load_after{i}(ix);
        hold(h(2), 'on')
        bar(h(2), ri, rel_load_after_2, 1, ...
            'FaceColor', ol_color, 'EdgeColor', ol_color, ...
            'LineWidth', 1.5, 'BaseValue', -1)
        plot(h(2), ri(ix2)*[1 1], [0, s.rel_load_after{i}(ix2)], ...
            '-', 'Linewidth', 2.5, 'Color', [0 0.8 0]);
	    if i <= length(s.pf_after)
            ix_end = s.pf_after(i);
            plot(h(2), ri(ix_end)*[1 1], [0, s.rel_load_after{i}(ix_end)], ...
                'r-', 'Linewidth', 3);
        end
        ix = s.pf_after(1:i-1);
        plot(h(2), ri(ix), zeros(size(ix)), 'r.', 'MarkerSize', 15);
        plot(h(2), xl, [1 1], 'k--')
        hold(h(2), 'off')
    end
    
    % set axes parameters and export to PNG
    set(h, 'XLim', xl, 'YLim', yl);
    set(h, 'FontSize', 20);
    set(h, 'Color', 'w');
    set(h, 'TickDir', 'out');
    set(h, 'XTick', 0:2000:8000);
    set(h, 'XTickLabel', []);
    set(h, 'YTick', 0:1:10);
    set(h, 'YTickLabel', []);
    if i <= length(s.pf_before) + 1
        fn = sprintf('%s/%05d_before.png', output_folder, i-1);
        fprintf(' saving to %s...\n',fn);
        saveas(fh1, fn, 'png');
    end
    if i <= length(s.pf_after) + 1
        fn = sprintf('%s/%05d_after.png', output_folder, i-1);
        fprintf(' saving to %s...\n',fn);
        saveas(fh2, fn, 'png');
    end
    
end

close(fh1);
close(fh2);


% Generate panel i of the figure

% Load the data
load(data_file)
i1 = 1:39;
cumsum_Proc_time_before = full(cumsum(Proc_time_before));
i2 = 1:207;
cumsum_Proc_time_after = full(cumsum(Proc_time_after));

% Print out the real time
for i = 4:215
    if i <= 50
        fprintf('Failure #% 3d, before: t = % .3f, after: t = % .3f\n', ...
            i-3, cumsum_Proc_time_before(i), cumsum_Proc_time_after(i));
    else
        fprintf('Failure #% 3d,                     after: t = % .3f\n', ...
            i-3, cumsum_Proc_time_after(i));
    end
end

% Get loading data
load(data_file_2, 'rel_load_before', 'rel_load_after');
ix2 = 7667; % This corresponds to Line #8720
for i = 1:length(rel_load_after)
    if ~isempty(rel_load_before{i})
	    rl1(i) = rel_load_before{i}(ix2);
    end
    rl2(i) = rel_load_after{i}(ix2);
end

% Plot the loading time series (for a specific line and for the total)
W = 4; H = 1.6;
fh3 = figure('Color', 'w', 'Visible', 'off', ...
    'PaperSize', [W,H], 'PaperPosition', [0,0,W,H]);
ha3 = axes(fh3);
i = i1; 
pt1 = cumsum_Proc_time_before(i+3);
pt = pt1;
rl = rl1;
t = reshape([0, pt(1:end-1); pt], [1, 2*length(pt)]);
y = reshape([rl(i); rl(i)], [1, 2*length(i)]);
h1 = plot(ha3, t, y, '-', 'Markersize', 8, 'LineWidth', 1.5);
hold(ha3, 'on')
i = i2;
pt2 = cumsum_Proc_time_after(i+3);
pt = pt2;
rl = rl2;
t = reshape([0, pt(1:end-1); pt], [1, 2*length(pt)]);
y = reshape([rl(i); rl(i)], [1, 2*length(i)]);
ix = ( y > 0.1 ); t = t(ix); y = y(ix);
h2 = plot(ha3, t, y, '-', 'Markersize', 8, 'LineWidth', 1.5);
for k = 1:5
   plot(ha3, pt1(k)*[1, 1], [0, 1], 'Color', h1.Color)
   plot(ha3, pt2(k)*[1, 1], [0, 1], 'Color', h2.Color)
end
plot(ha3, [0, 10], [1, 1], 'k--')
tt = [2.42, 2.90, 5.56, 7.65];
for k = 1:length(tt)
    plot(ha3, tt(k)*[1, 1], [0, 1.2], 'k-')
end
hold(ha3, 'off')

% Export the plots to files
box off
set(ha3, 'FontSize', 10, ...
    'XLim', [0 8], 'YLim', [0 1.2], ...
    'XTick', 0:2:10, 'YTick', 0:0.5:1)
filename = fullfile(output_folder, 'relative_loading_8720.pdf');
print(fh3, '-dpdf', filename)
delete(fh3)

toc
