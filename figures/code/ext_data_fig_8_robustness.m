function ext_data_fig_8_robustness
% Generates Extended Data Fig. 8 from the simulation results data in data_folder

disp('--- Generating Extended Data Fig 8 ---')

folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))

config = load_config();
data_folder = fullfile(config.data_folder, 'ext_data_fig_8_robustness');
output_folder = fullfile(config.output_folder, 'ext_data_fig_8_robustness');

% Ensure the output folder exists
if ~exist(output_folder, 'dir')
    mkdir(output_folder)
end

% Load result
stPF = 0; stPF0 = 0; vss = 0;
d = dir(fullfile(data_folder,'*.mat'));
for i = 1:length(d)
    s = load(fullfile(data_folder, d(i).name));
    stPF = stPF + s.stPF;
    stPF0 = stPF0 + s.stPF0;
    if exist('per','var') && any(per ~= s.per)
        error('mismatched "per"')
    end
    per = s.per;
    vss = vss + s.vss;
end

% add the per = 0 case
per = [0, per];
vss = [zeros(1,size(vss,2)); vss];

% Normalize by the total vulnerable set size of the original system before upgrades
vss0 = 1394;
vss_norm = vss/vss0;

font_size = 8;
ymax = 0.123;

c = 0.7;
w = 4.5*c; h = 3*c;
fh = figure('Visible', 'off', ...
    'PaperSize', [w h], 'PaperPosition', [0 0 w h]);

L = min(vss_norm,[],2);
U = max(vss_norm,[],2);
patch([per, per(end:-1:1), per(1)]*100, [L; U(end:-1:1); L(1)], '-', ...
    'LineWidth', 0.5, 'EdgeColor', 'none', 'FaceColor', [0.8 0.8 1])
hold on
plot(per*100, vss_norm, 'b.')
hold off
set(gca, 'FontSize', font_size, ...
    'XLim', [0 10], 'XTick', 0:2:10, ...
    'YLim', [0 ymax], 'YTick', 0:0.05:0.2)
box on

file_name = 'fig_robustness_export.png';
print(fh, '-dpng', '-r300', fullfile(output_folder, file_name))
close(fh)
