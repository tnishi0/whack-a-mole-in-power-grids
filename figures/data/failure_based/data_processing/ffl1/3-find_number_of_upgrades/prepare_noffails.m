% compute total number of failures including re-failing lines
clear all; close all;


ffl=1;
for i=0:20
    seed = i
    
   
    region='texas';
    load(['../../data/ffl',num2str(ffl),'/',region,'/texas_ffl',num2str(ffl),...
        '_K20000_demandRatio1.2_capRatio1_toInf0_seed',num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    fails=spones(fails(:,4:end));
    nf_tx = sum(fails,2);

    
    region='west';
    load(['../../data/ffl',num2str(ffl),'/',region,'/west_ffl',num2str(ffl),...
        '_K20000_demandRatio1_capRatio1_toInf0_seed',num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    fails=spones(fails(:,4:end));
    nf_w = sum(fails,2);


    region='east';
    load(['../../data/ffl',num2str(ffl),'/',region,'/cont_east_ffl',num2str(ffl),...
        '_K_init40000-K_final80000_demandRatio1_capRatio1_toInf0_seed',...
        num2str(seed),'.mat'],'cs')
    fails = cs.getHistoryFailureSeq;
    fails=spones(fails(:,4:end));
    nf_e = sum(fails,2);

    save(['NofFails_includingRe-failings/NofFails_ffl',num2str(ffl),'_seed',num2str(seed),'.mat'],...
        'nf_tx','nf_w','nf_e')

end