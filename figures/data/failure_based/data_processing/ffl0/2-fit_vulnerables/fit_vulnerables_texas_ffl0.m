close all; clear all;

ffl = 0;

% data files
load(['data/texas_vulnerables_ffl',num2str(ffl),'.mat'])
    
K=20000;

NofExp = size(vss,1);

fitted_vss_tx = zeros(NofExp,K);

for i=1:NofExp
    x = vss(i,:);
    y = log(x);
    yy = y(y > 0);
    temp_ci = cap_idx(y > 0);
    f = fit(temp_ci',yy','power2');
    xq_tx = 1:1:K;
    vq_tx = f(xq_tx);
    vq_tx = exp(vq_tx);
    fitted_vss_tx(i,:) = vq_tx;
end

save(['results/texas_K',num2str(K),'_ffl',num2str(ffl),...
        '_fitted_vulnerables.mat'],'xq_tx','fitted_vss_tx');

semilogy(xq_tx,fitted_vss_tx,'LineWidth',1)
hold on
plot(xq_tx,mean(fitted_vss_tx),'LineWidth',5)
ylim([1e-2,1000])



