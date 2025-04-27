close all; clear all;

ffl = 1;

% data files
load(['data/west_vulnerables_ffl',num2str(ffl),'.mat'])
    
K=20000;

NofExp = size(vss,1);

fitted_vss_w = zeros(NofExp,K);

for i=1:NofExp
    x = vss(i,:);
    y = log(x);
    yy = y(y > 0);
    temp_ci = cap_idx(y > 0);
    f = fit(temp_ci',yy','power2');
    xq_w = 1:1:K;
    vq_w = f(xq_w);
    vq_w = exp(vq_w);
    fitted_vss_w(i,:) = vq_w;
end

save(['results/west_K',num2str(K),'_ffl',num2str(ffl),...
        '_fitted_vulnerables.mat'],'xq_w','fitted_vss_w');

semilogy(xq_w,fitted_vss_w,'LineWidth',1)
hold on
plot(xq_w,mean(fitted_vss_w),'LineWidth',5)
ylim([1e-2,1000])



