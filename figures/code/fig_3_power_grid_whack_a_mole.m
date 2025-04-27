function fig_3_power_grid_whack_a_mole
% Create PNG files for the panels of Fig. 3

disp('--- Generating Fig 3 ---')

folder_path = fileparts(which(mfilename)); 
addpath(fullfile(folder_path, '../../library'))

t0 = tic;

dpi = 300;
a = 0.6; land_color = a*[136 144 138]/255 + (1-a)*[1 1 1];
a = 0.2; sea_color = a*[163 226 255]/255 + (1-a)*[1 1 1];

config = load_config();
data_folder = fullfile(config.data_folder, 'fig_3_power_grid_whack_a_mole');
data_file = fullfile(data_folder, 'compute_dist_rec_grid_transformed.mat');
fig_folder = fullfile(config.output_folder, 'fig_3_power_grid_whack_a_mole');

% Ensure the output folder exists
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end

% Load the data
load( ...
    data_file, ...
    'nl', 'nf', 'clon', 'clat', 'z', 'coast', 'lake_borders', ...
    'rmax', 'lon_min', 'lon_max', 'lat_min', 'lat_max' ...
)

% Create the figure
fh = figure('Color', sea_color, 'Visible', 'off', 'InvertHardcopy', 'off');
ah = axes();
xlim(ah, [lon_min, lon_max])
ylim(ah, [lat_min, lat_max])
set(ah, 'Position', [0 0 1 1]);
axis(ah,'off')

% Adjust the figure size.
pos = get(fh, 'Position');
xl = xlim(ah); yl = ylim(ah);
width = xl(2) - xl(1); height = yl(2) - yl(1);
pos(4) = pos(3)*(height/width);
set(fh, 'Position', pos);

hold(ah, 'on')

% Draw the map
k = find(isnan(coast(:,1)));
if k(1)~=1; k = [0;k(:)];end
for i = 1:length(k)-1
    x = coast([k(i)+1:(k(i+1)-1) k(i)+1],1);
    y = coast([k(i)+1:(k(i+1)-1) k(i)+1],2);
    n = length(x(:));
    v = [x y zeros(n,1)];
    f = 1:n;
    patch(ah, 'Vertice', v, 'Faces', f, 'FaceColor', land_color, ...
        'LineStyle', '-', 'EdgeColor', 'none', 'LineWidth', 0.3);
end

hold on

% Lakeshore lines
for j = [8, 15, 27:29]
    coast = [lake_borders(j).X', lake_borders(j).Y'];
    k = find(isnan(coast(:,1)));
    if k(1)~=1; k = [0;k(:)];end
    for i = 1:length(k)-1
        x = coast([k(i)+1:(k(i+1)-1) k(i)+1],1);
        y = coast([k(i)+1:(k(i+1)-1) k(i)+1],2);
        n = length(x(:));
        v = [x y zeros(n,1)];
        f = 1:n;
        patch(ah, 'Vertice', v, 'Faces', f, 'FaceColor', sea_color, ...
            'LineStyle', '-', 'EdgeColor', 'none', 'LineWidth', 0.3);
    end
end

% Plot density of power lines
z = z/0.5;
imagesc(clon, clat, ones(size(z)), 'AlphaData', z)
colormap([0, 0, 0; 0, 0, 1])
axis xy

% The radius of the circle for a county with zz = zz_max will be rmax.
zz_max = 0.5; 

% Draw red circles for counties for which the average number of failures
% per line increased from before to after the iteration.  Draw blue dots
% for all the other counties for which there is at least 1/2 of a line
% (i.e., there is a line ending in that county).
[Plon,Plat] = meshgrid(clon, clat);
for iter = 1 : length(nf) - 1

    t1 = tic;
    
    fprintf('=== iter = %d ===\n', iter);
    fprintf('Drawing...');
    
    % The increase in the number of failures per line in the county
    zz = (nf{iter+1} - nf{iter}) ./ nl;
    r = sqrt(zz/zz_max)*rmax;
    
    ix = find( zz > 0 );
    hp = gobjects(1,length(ix));
    h = gobjects(1,length(ix));
    for k = 1:length(ix)
        i = ix(k);
        hp(k) = plot(ah, Plon(i), Plat(i), 'r.', 'MarkerSize', 0.5);
        h(k) = draw_circle(ah, hp(k).XData, hp(k).YData, r(i));
    end
    disp(' Done.')

    % Legend
    if iter == 1
        h(k+1) = draw_circle(ah, 0.2936, 1.0363, sqrt(0.5/zz_max)*rmax);
        h(k+2) = draw_circle(ah, 0.2936, 1.0161, sqrt(0.1/zz_max)*rmax);
    end    
    
    set(h, 'FaceColor', 'r', 'EdgeColor', 'r', 'FaceAlpha', 0.4, ...
    	'EdgeAlpha', 0.6, 'LineWidth', 0.05);           
    
    fn = fullfile(fig_folder, sprintf('iter%02d.png', iter));
    fprintf('Saving to "%s"...', fn);
    print(fh, '-dpng', ['-r',num2str(dpi)], fn);
    disp(' Done.')
    toc(t1)

    delete(h)
    delete(hp)
    
end

toc(t0)


function h = draw_circle(ah, x, y, r)

n = 30;
th = 0:2*pi/n:2*pi;
h = patch(ah, x + r*cos(th), y + r*sin(th), 'r');
