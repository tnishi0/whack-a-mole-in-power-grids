close all; clear all;

% find capacity profile of
%dataName = 'texas'; demand_ratio = 1.2; nofbranches=9395; K=20000; c=1;
dataName = 'west'; demand_ratio = 1.0; nofbranches=25559; K=20000; c=2;
%dataName = 'east'; demand_ratio = 1.0; nofbranches=95856; K=40000; c=3;
line_cap_ratio = 1.0;
seed = 0:19; % seed number
toInf = 0; % 0:overloaded; 1:to infinity

ffl=0;


load(['ffl',num2str(ffl),'_critical_indeces.mat']);

caps_it = zeros(length(seed), nofbranches);

for i=1:length(seed)
    disp(['seed:',num2str(seed(i))])
    
    fileName=[dataName,'_ffl',num2str(ffl),...
        '_K',num2str(K),...
        '_demandRatio',num2str(demand_ratio),...
        '_capRatio',num2str(line_cap_ratio),...
        '_toInf',num2str(toInf),...
        '_seed',num2str(seed(i))];
    
    load(['data/',dataName,'/',fileName,'.mat'], 'caps'); %existance of the file

    iteration = critical_idx(i,c);
    caps_it(i,:) = caps(iteration,:);
end


save(['results/',dataName,'_ffl',num2str(ffl),'_caps_profile.mat'],'caps_it')

