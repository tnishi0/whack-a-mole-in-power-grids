classdef CountyMapCapUpg < CountyMap
    methods(Access = public)
        function set_colors(obj, variable_name)
            assert(ischar(variable_name))          
            num_colors = 100;
            timer = Timer('Updating the county_map');
            switch variable_name
                case 'capacity_upgrades'
                    % Calculate and add the log-scaled relative capacity increase for each county.
                    % Note that if initial capacity is zero, it will give NaN.
                    cap_upg = obj.get_values('capacity_upgrades');
                    init_caps = obj.get_values('initial_capacitites');
                    lb = -2; ub = 1; % lower and upper bounds for the log10 of relative capacity increase
                    log_rel_values = log10(cap_upg ./ init_caps);
                    log_rel_values(log_rel_values > ub) = ub; % Cap values at the upper bound
                    color_indices = ceil((log_rel_values - lb) / (ub - lb) * num_colors);

                    % cap_upg = 0 will give log_rel_values = -inf, setting the index to 1 here
                    % (corresponding to county_map.land_color)
                    color_indices(cap_upg == 0) = 1;

                    % Set the colors of the counties on the map
                    obj.value_color = [0 0 0.8];
                    obj.set_colors@CountyMap(color_indices)
                    
                    % Update the color bar
                    color_bar_ticks = ((lb:ub) - lb) / (ub - lb) * num_colors;
                    color_bar_tick_labels = {'10^{-2}','10^{-1}','10^{0}','10^{1}'};
                    assert(length(color_bar_tick_labels) == length(color_bar_ticks))
                    obj.color_bar_handle.Ticks = color_bar_ticks;
                    obj.color_bar_handle.TickLabels = color_bar_tick_labels;

                case 'num_upgraded_lines'
                    num_upgraded_lines = obj.get_values('num_upgraded_lines');
                    num_lines = obj.get_values('num_lines');
                    lb = 0; ub = 0.3;
                    frac_upg_lines = num_upgraded_lines ./ num_lines;
                    frac_upg_lines(frac_upg_lines > ub) = ub; % Cap values at the upper bound
                    color_indices = ceil((frac_upg_lines - lb) / (ub - lb) * num_colors);

                    % num_lines = 0 will give log_rel_values = -inf, setting the index to 1 here
                    % (corresponding to county_map.land_color)
                    color_indices(num_lines == 0) = 1;

                    % Set the colors of the counties on the map
                    obj.value_color = [0 0.8 0];
                    obj.set_colors@CountyMap(color_indices)

                    % Update the color bar
                    color_bar_ticks = ((0:0.1:0.3) - lb)/(ub - lb)*num_colors;
                    color_bar_tick_labels = {' 0%', '10%', '20%', '30%'};
                    assert(length(color_bar_tick_labels) == length(color_bar_ticks))
                    obj.color_bar_handle.Ticks = color_bar_ticks;
                    obj.color_bar_handle.TickLabels = color_bar_tick_labels;

                otherwise
            end            
            timer.stop();          
        end

        function [n, percentage] = num_counties_upg_lines(obj, p)
            % Number and fraction of counties that had their capacity increased by more than p percent
            arguments (Input)
                obj (1,1) CountyMapCapUpg
                p (1,1) {mustBeNumeric, mustBeInRange(p, 0, 100)}
            end
            arguments (Output)
                n (1,1) {mustBeInteger}
                percentage (1,1) {mustBeNumeric, mustBeInRange(percentage, 0, 100)}
            end
            cap_upg = obj.get_values('capacity_upgrades');
            init_caps = obj.get_values('initial_capacitites');
            n = sum(cap_upg ./ init_caps > p / 100);
            percentage = n / length(cap_upg) * 100;
            if nargout == 0
                fprintf( ...
                    '%d counties (%.1f%%) had their capacity increased by more than %.0f%%\n', ...
                    n, percentage, p ...
                );
                clear n percentage
            end
        end
    end
end
