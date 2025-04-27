close all; clear all;

% data files to combine
dataName = {'texas','west','east','east','east','east','east','east'};
demand_ratio = [1.2,1.0,1.0,1.0,1.0,1.0,1.0,1.0];
TrigSubset = [false,false,true,true,true,true,true,true];  % true for the east part
region_idx = [1,1,1,2,3,4,5,6]; % sub regions of east from 1 to 6

% Subregion names
subregions = {'FRCC', 'MRO', 'NPCC', 'RFC', 'SERC', 'SPP'};

idx_data = 1; % 1: texas; 2: west; 3-8: east regions

K = 20000; % Number of realizations
line_cap_ratio = 1.0;
seed = 0:19; % seed number
toInf = 0; % 0:overloaded; 1:to infinity

NofExp = size(seed, 2);

ffl = 0;
vul_set = zeros(NofExp, 40);

for s = 1:length(seed)
    
    disp(['seed:', num2str(seed(s)), ', ffl: ', num2str(ffl), ...
        ', data: ', dataName{idx_data}])

    % Adaptively create the file name based on region
    if idx_data >= 3 && idx_data <= 8  % For east region
        region_str = subregions{region_idx(idx_data - 2)};  % Get region sub number for East
        fileName = [dataName{idx_data},'_ffl', num2str(ffl), '_trigReg-', region_str, ...
            '_K', num2str(K), ...
            '_demandRatio', num2str(demand_ratio(idx_data)), ...
            '_capRatio', num2str(line_cap_ratio), ...
            '_toInf', num2str(toInf), ...
            '_seed', num2str(seed(s))];
    else  % For texas and west
        fileName = [dataName{idx_data}, '_ffl', num2str(ffl), ...
            '_K', num2str(K), ...
            '_demandRatio', num2str(demand_ratio(idx_data)), ...
            '_capRatio', num2str(line_cap_ratio), ...
            '_toInf', num2str(toInf), ...
            '_seed', num2str(seed(s))];
    end
    
    load(['data/tvuls_', fileName, '.mat']);

    vul_set(s, :) = vss;

end
vss = vul_set;

% Save results
save(['results/', dataName{idx_data}, '_vulnerables_ffl', num2str(ffl)], 'cap_idx', 'vss');