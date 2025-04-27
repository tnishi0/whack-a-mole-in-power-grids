clear all;
close all;

dataName = 'east'; demand_ratio = 1.0; nofbranches=95856; K=40000; c=3;
line_cap_ratio = 1.0;
seed = 0:19; % seed number
toInf = 0; % 0:overloaded; 1:to infinity

ffl=1;


load(['ffl',num2str(ffl),'_critical_indeces.mat']);

caps_it = zeros(length(seed), nofbranches);

for i=1:length(seed)
    iteration = critical_idx(i,c);
    it_low = floor(iteration*0.001)*1000;
    it_high= it_low + 1000;
    x = load(['data/east/cont_caps_iter',num2str(it_low),'_east_ffl1_K40000_demandRatio1_capRatio1_toInf0_seed'...
        ,num2str(seed(i)),'.mat']);
    y = load(['data/east/cont_caps_iter',num2str(it_high),'_east_ffl1_K40000_demandRatio1_capRatio1_toInf0_seed'...
        ,num2str(seed(i)),'.mat']);
    x = x.caps;  y = y.caps;  
    z = x + (iteration-it_low)*0.001*(y-x);
    z(isnan(z)) = Inf;
    caps_it(i,:) = z;
end


save(['results/east_ffl',num2str(ffl),'_caps_profile.mat'],'caps_it')
