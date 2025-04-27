% This script combines the raw simulation results files (excluded from this repository to comply with an NDA)
% into two data files in this folder

close all; clear all;

% data files to combine
dataName = {'texas','west','east','east','east','east','east','east'};
demand_ratio = [1.2,1.0,1.0,1.0,1.0,1.0,1.0,1.0];
TrigSubset = [false,false,true,true,true,true,true,true];  % true for the east part
region_idx = [1,1,1,2,3,4,5,6]; % sub regions of east from 1 to 6


K = 10000; % Number of realizations
line_cap_ratio = 1.0;
seed = 0; % seed number
NofInc = 10;
ffl=1;


nOfIncs = zeros(21,10); % number of increases
instCaps = zeros(21,11); % instant total capacity
vulSetSize = zeros(21,11);

for i=1:length(dataName)
    disp([num2str(i),', data:', dataName{i}])

    fileName = get_filename(dataName{i},ffl,...
        TrigSubset(i), region_idx(i),K,NofInc,demand_ratio(i),...
        line_cap_ratio,seed);

    load([fileName,'.mat']);

    nOfIncs = nOfIncs + NofIncLines;
    instCaps = instCaps + caps;
    vulSetSize = vulSetSize + vulSetCount;

end

 fn=['combined_ffl',num2str(ffl),...
        '_K',num2str(K),...
        '_seed',num2str(seed)];

    save([fn,'.mat'], 'nOfIncs', 'instCaps', 'vulSetSize', 'ffl_threshold')


%% Data load
function fileName = get_filename(dataName,ffl,...
    TrigSubset,region_idx,K,NofInc,demand_ratio,line_cap_ratio,seed)

if TrigSubset
    
    switch region_idx
        case 1
            region = 'FRCC';
        case 2 
            region = 'MRO';
        case 3
            region = 'NPCC';
        case 4
            region = 'RFC';
        case 5
            region = 'SERC';
        case 6
            region = 'SPP';
    end
      
    fileName=[dataName,'_trigReg-',region,...
        '_ffl',num2str(ffl),...
        '_K',num2str(K),...
        '_NofInc', num2str(NofInc),...
        '_demandRatio',num2str(demand_ratio),...
        '_capRatio',num2str(line_cap_ratio),...
        '_seed',num2str(seed,'%02d')];
else
    fileName=[dataName,'_ffl',num2str(ffl),...
        '_K',num2str(K),...
        '_NofInc', num2str(NofInc),...
        '_demandRatio',num2str(demand_ratio),...
        '_capRatio',num2str(line_cap_ratio),...
        '_seed',num2str(seed,'%02d')];
end
end

