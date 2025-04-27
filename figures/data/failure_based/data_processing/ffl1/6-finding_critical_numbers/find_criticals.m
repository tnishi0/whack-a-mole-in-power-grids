% compute critical numbers (vss < treshold) such as # of cascades, upgrades
% failures etc for each interconnection

clear all; close all;

ffl = 1;

load(['data/ffl',num2str(ffl),'_critical_indeces.mat']);

NofCascades = zeros(20,2); % store number of cascades and critical iteration
NofFailures = zeros(20,2); % store number of cascades and critical iteration
NofUniqueUpgrades = zeros(20,2); % store number of cascades and critical iteration
for i=1:20
    seed=i-1;
    load(['data/NofFails_includingRe-failings/NofFails_ffl',num2str(ffl),'_seed',num2str(seed),'.mat'])
    
    NofCascades(i,1) = sum(critical_idx(i,:));
    NofCascades(i,2) = nnz(nf_tx(1:critical_idx(i,1))) + ...
        nnz(nf_w(1:critical_idx(i,2))) + nnz(nf_e(1:critical_idx(i,3)));
    
    NofFailures(i,1) = sum(critical_idx(i,:));
    NofFailures(i,2) = sum(nf_tx(1:critical_idx(i,1))) + ...
        sum(nf_w(1:critical_idx(i,2))) + sum(nf_e(1:critical_idx(i,3)));
    
    load(['data/NofUniqueUpg/NofUpgrades_ffl',num2str(ffl),'_seed',num2str(seed),'.mat'])
    NofUniqueUpgrades(i,1) = sum(critical_idx(i,:));
    NofUniqueUpgrades(i,2) = nnz(nu_tx(1:critical_idx(i,1))) + ...
        nnz(nu_w(1:critical_idx(i,2))) + nnz(nu_e(1:critical_idx(i,3)));
end


save(['results/ffl',num2str(ffl),'_criticals.mat'],...
    'NofCascades','NofFailures', 'NofUniqueUpgrades');
