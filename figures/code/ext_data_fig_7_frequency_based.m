function ext_data_fig_7_frequency_based
% Create panels a-f and a draft of the overall figure for Extended Data Figure 7

disp('--- Generating Extended Data Fig 7 ---')

folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))

tic

config = load_config();
data_folder = fullfile(config.data_folder, 'ext_data_fig_7_frequency_based');
output_folder = fullfile(config.output_folder, 'ext_data_fig_7_frequency_based');

% Ensure the output folder exists
if ~exist(output_folder, 'dir')
    mkdir(output_folder)
end

disp('Job Started...');

%% general graphics, this will apply to any figure you open
% (groot is the default figure object).
set(groot, ...
'DefaultFigureColor', 'w', ...
'DefaultAxesLineWidth', 0.5, ...
'DefaultAxesXColor', 'k', ...
'DefaultAxesYColor', 'k', ...
'DefaultAxesFontUnits', 'points', ...
'DefaultAxesFontSize', 12, ...
'DefaultAxesFontName', 'Helvetica', ...
'DefaultLineLineWidth', 2, ...
'DefaultTextFontUnits', 'Points', ...
'DefaultTextFontSize', 12, ...
'DefaultTextFontName', 'Helvetica', ...
'DefaultAxesBox', 'off', ...
'DefaultAxesTickLength', [0.02 0.025]);
 
% set the tickdirs to go out - need this specific order
set(groot, 'DefaultAxesTickDir', 'out');
set(groot, 'DefaultAxesTickDirMode', 'manual');

%% data parameters.
ffl = 0;
fn = ['combined_ffl',num2str(ffl),'_K10000_seed1'];

file_name = [fn,'.mat'];
load(fullfile(data_folder, file_name))

NofInc=10;
%% prepare results to plot - first failing lines

diffV = zeros(length(ffl_threshold),NofInc+1);
for i=1:NofInc
    diffV(:,i+1) = vulSetSize(:,1)-vulSetSize(:,i+1);
end

nil = cumsum(nOfIncs');

nil = nil';
nil = [zeros(size(nil(:,1))) nil];

caps = instCaps-instCaps(1);
caps = [zeros(size(caps(:,1))) caps];

% thr= 0:20; % selected thresholds
k = 1:21;
iter= 0:10; % selected thresholds

%% plot

fig = figure('Visible', 'off');

set(fig, 'Position', [100 100 1000 700])
set(fig, 'PaperPosition', [0 0 10 7]);
set(fig, 'PaperSize', [10 7]); 

ax = axes(fig);
h = subplot(2,3,1,ax);
imagesc(iter,k,vulSetSize,[0 1500]);
h.Box = 'off';
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
c = colorbar;
c.Label.Interpreter = 'latex';
c.Label.String = '$\|V\|$';
c.Location = 'northoutside';
ylabel('threshold (k)','Interpreter','latex')
save_panel(h, 'panel_a', output_folder)
save_panel_colorbar([h c], 'colorbar_a', output_folder)

axis_height = h.Position(4);

h = subplot(2,3,2);
imagesc(iter,k,nil,[0 1e4]);
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
h.YTickLabels = {};
h.Position(1) = h.Position(1) - 0.04;
h.Box = 'off';
c = colorbar;
c.Label.String = 'number of upgrades';
c.Label.Interpreter = 'latex';
c.Location = 'northoutside';
save_panel(h, 'panel_b', output_folder)
save_panel_colorbar([h c], 'colorbar_b', output_folder)

h = subplot(2,3,3);
imagesc(iter,k,caps(:,2:end),[0 6.0765e+06]);
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
h.YTickLabels = {};
h.Position(1) = h.Position(1) - 0.08;
h.Box = 'off';
c = colorbar;
c.Label.String = 'increased capacity (MVA)';
c.Label.Interpreter = 'latex';
c.Location = 'northoutside';
save_panel(h, 'panel_c', output_folder)
save_panel_colorbar([h c], 'colorbar_c', output_folder)

%% ffl = 1

ffl = 1;
fn = ['combined_ffl',num2str(ffl),'_K10000_seed1'];

file_name = [fn,'.mat'];
load(fullfile(data_folder, file_name))

NofInc=10;


diffV = zeros(length(ffl_threshold),NofInc+1);
for i=1:NofInc
    diffV(:,i+1) = vulSetSize(:,1)-vulSetSize(:,i+1);
end

nil = cumsum(nOfIncs');

nil = nil';
nil = [zeros(size(nil(:,1))) nil];

caps = instCaps-instCaps(1);
caps = [zeros(size(caps(:,1))) caps];

k = 1:21; % selected thresholds
iter= 0:10; % selected thresholds


h = subplot(2,3,4);
imagesc(iter,k,vulSetSize,[0 1500]);
h.Box = 'off';
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
h.Position(2) = h.Position(2) + 0.18;
h.Position(4) = axis_height;
xlabel('iteration ($m$)','Interpreter','latex')
ylabel('threshold (k)','Interpreter','latex')
save_panel(h, 'panel_d', output_folder)

h = subplot(2,3,5);
imagesc(iter,k,nil,[0 1e4]);
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
h.YTickLabels = {};
h.Box = 'off';
h.Position(1) = h.Position(1) - 0.04;
h.Position(2) = h.Position(2) + 0.18;
h.Position(4) = axis_height;
xlabel('iteration ($m$)','Interpreter','latex')
save_panel(h, 'panel_e', output_folder)

h = subplot(2,3,6);
imagesc(iter,k,caps(:,2:end),[0 6.0765e+06]);
h.XLim = [-0.5 10.5];
h.XTick = 0:5:10;
h.XTickLabels = {};
h.YTick = [1 10 20];
h.YTickLabels = {};
h.Position(1) = h.Position(1) - 0.08;
h.Position(2) = h.Position(2) + 0.18;
h.Box = 'off';
xlabel('iteration ($m$)','Interpreter','latex')
h.Position(4) = axis_height;
save_panel(h, 'panel_f', output_folder)

%% save fig
file_name = 'figure.pdf';
saveas(fig, fullfile(output_folder, file_name), 'pdf')
close(fig)
fprintf('Saved figure to "%s"\n', file_name);

toc


function save_panel(h, fn_base, output_folder)

fig_panel = figure('PaperPosition', [0 0 2 1.8], 'PaperSize', [2 1.8], ...
    'Visible', 'off');
h_panel = copyobj(h, fig_panel);
h_panel.Position = [0.05 0.05 0.9 0.9];
file_name = [fn_base,'.svg'];
saveas(fig_panel, fullfile(output_folder, file_name), 'svg')
close(fig_panel)


function save_panel_colorbar(h, fn_base, output_folder)

fig_panel = figure('PaperPosition', [0 0 2 1.8], 'PaperSize', [2 1.8], ...
    'Visible', 'off');
h_panel = copyobj(h, fig_panel);
h_panel(1).Position = [0.05 0.05 0.9 0.9];
file_name = [fn_base,'.svg'];
saveas(fig_panel, fullfile(output_folder, file_name), 'svg')
close(fig_panel)
