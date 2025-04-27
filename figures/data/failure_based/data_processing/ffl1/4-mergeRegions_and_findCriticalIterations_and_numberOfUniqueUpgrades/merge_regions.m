clear all;
close all;
%% general graphics, this will apply to any figure you open
% (groot is the default figure object).
set(groot, ...
'DefaultFigureColor', 'w', ...
'DefaultAxesLineWidth', 0.5, ...
'DefaultAxesXColor', 'k', ...
'DefaultAxesYColor', 'k', ...
'DefaultAxesFontUnits', 'points', ...
'DefaultAxesFontSize', 10, ...
'DefaultAxesFontName', 'Calibri', ...
'DefaultLineLineWidth', 2, ...
'DefaultTextFontUnits', 'Points', ...
'DefaultTextFontSize', 8, ...
'DefaultTextFontName', 'Helvetica', ...
'DefaultAxesBox', 'off', ...
'DefaultAxesTickLength', [0.02 0.025]);
 
% set the tickdirs to go out - need this specific order
set(groot, 'DefaultAxesTickDir', 'out');
set(groot, 'DefaultAxesTickDirMode', 'manual');

%% set a seed to rng
rng(1);


%% load results
ffl = 1;
load(['data/east_K80000_ffl',num2str(ffl),'_fitted_vulnerables.mat'])
load(['data/west_K20000_ffl',num2str(ffl),'_fitted_vulnerables.mat'])
load(['data/texas_K20000_ffl',num2str(ffl),'_fitted_vulnerables.mat'])

NofExp = min([size(fitted_vss_tx,1),size(fitted_vss_w,1),size(fitted_vss_e,1)]);
% texas only 7854 points
n_tx = 7854;
xq_tx = xq_tx(1:7854); % iteration number 

% west increase to 21328 
n_w = 21328;
xq_w(20001:21328) = 20001:n_w;

% east arrangements for 80000
n_e = 80000;

n = n_tx + n_w + n_e;
x = 1:n; % iteration
fitted_vss = zeros(NofExp,n);

nu = zeros(NofExp,n); % total number of unique upgrades

% store critical iteration for each interconnection
critical_idx = zeros(NofExp,3); 
thr = 15; % threshold for total number of vulnerable lines

step_upg= zeros(NofExp,2); % critical step and number of unique upgrades

for i=1:NofExp
    
    seed=i-1;
    load(['NofUniqueUpg/NofUpgrades_ffl',num2str(ffl),'_seed',num2str(seed),'.mat'])
    nu_tx = nu_tx(1:n_tx);
    nu_w(20001:n_w) = 0;
    
    % Texas arrangements
    vq_tx = fitted_vss_tx(i,:);
    vq_tx = vq_tx(1:7854); 
    
    % West arrangements
    vq_w = fitted_vss_w(i,:);
    vq_w(20001:21328) = 0;
    
    % East arrangements
    vq_e = fitted_vss_e(i,:);
    
    % shuffle the failures
    p = [ones(1,length(xq_tx)) 2*ones(1,length(xq_w)) 3*ones(1,length(xq_e))];
    shuffle = randperm(length(p)); % shuffle the numbers
    pn = p(shuffle); 

%     t_xq = length(pn); % # of iterations
% 
%     x = 1:t_xq; % iteration
%     v = zeros(1,t_xq); % total number of vulnerables 

    ids = [1 1 1]; 
    for j=1:n
        idx = pn(j);
        fitted_vss(i,j) =vq_tx(ids(1))+vq_w(ids(2))+vq_e(ids(3));    

        if idx == 1
            nu(i,j) = nu_tx(ids(idx));
        elseif idx == 2
            nu(i,j) = nu_w(ids(idx));
        elseif idx == 3
            nu(i,j) = nu_e(ids(idx));
        end
        
     
        
        val = ids < [n_tx n_w n_e]; % validiation
        if val(idx) == 1
            ids(idx) = ids(idx) + 1; 
        end  
    end
    
    nu(i,:) = spones(nu(i,:)); % only one line is upgraded (ffl1)
    
    % find critical numbers for each interconnection
    critics = find(fitted_vss(i,:)<thr,1,'first'); % global criticality
    critical_idx(i,1) = sum(pn(1:critics) == 1); % texas
    critical_idx(i,2) = sum(pn(1:critics) == 2); % west
    critical_idx(i,3) = sum(pn(1:critics) == 3); % east
    
    step_upg(i,1)  = critics;
    step_upg(i,2)  = sum(nu(i,1:critics));
end


save(['results/ffl',num2str(ffl),'_fitted_vulnerables.mat'],...
    'x','fitted_vss');
    
save(['results/ffl',num2str(ffl),'_critical_indeces.mat'],...
    'critical_idx');

save(['results/ffl',num2str(ffl),'_number_of_unique_upgrades.mat'],...
    'nu');

save(['results/ffl',num2str(ffl),'_step_and_unique_upgrades.mat'],...
    'step_upg');

fig = figure;
fig.Renderer='Painters';
set(fig, 'Position', [100 100 1000 450])

subplot(211)
plot(x, fitted_vss)
hold on
plot(x, mean(fitted_vss),'LineWidth',5)
ylabel('size of vs')

set(gca, 'YTick', [10.^0 10.^1 10.^2 10.^3 10.^4 10.^5 10.^6 10.^7 10.^8 10.^9 10.^10])
set(gca,'YScale','log')

% plot(f,tt,yy)
% plot(tt,exp(vv));
% plot(t,vvv);
subplot(212)
plot(x, cumsum(nu,2))
hold on
plot(x, cumsum(mean(nu,1)),'LineWidth',5)
ylabel('# of Unique Upgrades')
xlabel('iteration')


% ylim([1,1e1]);
set(gca, 'YTick', [10.^0 10.^1 10.^2 10.^3 10.^4 10.^5 10.^6 10.^7 10.^8 10.^9 10.^10])
set(gca,'YScale','log')

set(gcf, 'PaperPosition', [0 0 14 7]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [14 7]); %Set the paper to have width 5 and height 5.

