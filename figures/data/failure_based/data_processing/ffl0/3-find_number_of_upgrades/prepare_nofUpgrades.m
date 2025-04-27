% compute number of upgrades
clear all; close all;

ffl=0;
for i=0:20
    seed = i
    
    
    region='texas';
    load(['../../data/ffl',num2str(ffl),'/',region,'/texas_ffl',num2str(ffl),...
        '_K20000_demandRatio1.2_capRatio1_toInf0_seed',num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    [~,ix]=unique(fails(:,4:end),'stable');
    fails(ix) = 1;
    fails(fails ~= 1)=0;
    nu_tx = sum(fails,2);

    

    region='west';
    load(['../../data/ffl',num2str(ffl),'/',region,'/west_ffl',num2str(ffl),...
        '_K20000_demandRatio1_capRatio1_toInf0_seed',num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    [~,ix]=unique(fails(:,4:end),'stable');
    fails(ix) = 1;
    fails(fails ~= 1)=0;
    nu_w = sum(fails,2);


    region='east';
    load(['../../data/ffl',num2str(ffl),'/',region,'/cont_east_ffl',num2str(ffl),...
        '_K_init40000-K_final80000_demandRatio1_capRatio1_toInf0_seed',...
        num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    [~,ix]=unique(fails(:,4:end),'stable');
    fails(ix) = 1;
    fails(fails ~= 1)=0;
    nu_e = sum(fails,2);


    save(['NofUniquesUpg/NofUpgrades_ffl',num2str(ffl),'_seed',num2str(seed),'.mat'],...
        'nu_tx','nu_w','nu_e')

end

% bar(nf_tx, 'BarWidth', 75,'FaceColor','k');
% hold on
% bar(nf_w, 'BarWidth', 75,'FaceColor','r');
% bar(nf_e, 'BarWidth', 75,'FaceColor','b');