% Print the stats for the county map for the 3 strategies (first-failure cases)
disp('--- Stats related to Fig 4 ---')
tic
clear
folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))
config = load_config();
data_folder = fullfile(config.data_folder, 'fig_4_county_maps');
for i = 1 : length(config.strategies)
    strategy = config.strategies{i};
    fprintf('* %s strategy:\n', strategy);
    file_name = sprintf('fig_county_maps_compute_%s.mat', strategy);
    load(fullfile(data_folder, file_name), 'county_map')
    county_map.num_counties_upg_lines(0)
    county_map.num_counties_upg_lines(20)
end
toc
