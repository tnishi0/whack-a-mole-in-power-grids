close all; clear all;

ffl = 1;

% data files
load(['data/east_vulnerables_ffl',num2str(ffl),'.mat'])
    
K=80000;

NofExp = size(vss,1);

fitted_vss_e = zeros(NofExp,K);

for i=1:NofExp
    x = vss(i,:);
    y = log(x);
    yy = y(y > 0);
    cap_idx = cap_idx(y > 0);
    f = fit(cap_idx',yy','power2');
    xq_e = 1:1:K;
    vq_e = f(xq_e);
    vq_e = exp(vq_e);
    fitted_vss_e(i,:) = vq_e;
end

save(['results/east_K',num2str(K),'_ffl',num2str(ffl),...
        '_fitted_vulnerables.mat'],'xq_e','fitted_vss_e');

semilogy(xq_e,fitted_vss_e,'LineWidth',1)
hold on
plot(xq_e,mean(fitted_vss_e),'LineWidth',5)
    



