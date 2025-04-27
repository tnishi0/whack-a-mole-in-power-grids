classdef CountyMap
    % Class for object representing the map of U.S. counties, with a given quantity color-coded

    properties (Access = public)
        num_colors = 100
        value_color = [0 0 0.8]
        cartgram_transform_on = true
    end

    properties (GetAccess = public, SetAccess = protected)
        num_counties
        counties
        variable_names = []
        fig_handle
        axes_handle
        color_bar_handle
        land_color = 0.2*[136 144 138]/255 + 0.8*[1 1 1]
    end

    methods
        function obj = set.value_color(obj, value_color)
            % Set the color whose intensity will be used for coding the value
            obj.value_color = value_color;
            obj.update_colormap();
        end

        function obj = set.cartgram_transform_on(obj, value)
            if obj.cartgram_transform_on == value
                return
            end
            mustBeMember(value, [true, false])
            obj.cartgram_transform_on = value;
            obj.update_boundaries();
        end

        function obj = update_boundaries(obj)
            for i = 1 : obj.num_counties
                obj.counties{i} = update_boundaries(obj.counties{i}, obj.cartgram_transform_on);
            end
        end
    end

    methods (Access = public)
        function obj = CountyMap(config)
            if nargin < 1
                config = load_config();
            end
            data_folder = fullfile(config.data_folder, 'counties_data');
            boundaries_file = fullfile(data_folder, 'area_counties.mat');
            boundaries_variable = 'sh_counties';
            transformed_boundaries_variable = 'sh_counties_carto';
            transformed_boundaries_file = fullfile(data_folder, 'area_counties_carto.mat');

            % Load the boundary data and check consistency
            timer = Timer('Loading boundary data');
            s = load(boundaries_file, boundaries_variable);
            boundaries = s.(boundaries_variable);
            assert(isvector(boundaries))
            s = load(transformed_boundaries_file, transformed_boundaries_variable);
            transformed_boundaries = s.(transformed_boundaries_variable);
            assert(isvector(transformed_boundaries))
            assert(length(transformed_boundaries) == length(boundaries))
            obj.num_counties = length(boundaries);
            timer.stop()

            % Create the figure and axes
            obj.fig_handle = figure( ...
                'Color', 'w', ...
                'Position', [1,5,1440,650], ...
                'PaperSize', [3.2,1.5], ...
                'PaperPosition', [0,0,3.2,1.5], ...
                'Visible', 'off', ...
                'InvertHardcopy', 'off' ...
            );
            obj.axes_handle = axes( ...
                obj.fig_handle, ...
                'Position', [0,0,1,1], ...
                'FontSize', 8, ...
                'Color', 'none' ...
            );
            axis(obj.axes_handle, 'equal', 'off')
            xlim(obj.axes_handle, [-125, -65])

            % Create list of County objects and draw the counties
            timer = Timer('Creating County objects');
            obj.counties = cell(obj.num_counties, 1);
            for i = 1 : obj.num_counties
                name = boundaries(i).NAME;
                county_boundaries.latitude = boundaries(i).Y;
                county_boundaries.longitude = boundaries(i).X;
                county_boundaries.state = boundaries(i).STATE;
                transformed_county_boundaries.latitude = transformed_boundaries(i).Y;
                transformed_county_boundaries.longitude = transformed_boundaries(i).X;
                obj.counties{i} = County( ...
                    name, county_boundaries, transformed_county_boundaries ...
                );
                obj.counties{i} = draw( ...
                    obj.counties{i}, ...
                    obj.axes_handle, obj.cartgram_transform_on ...
                );
            end
            timer.stop()

            obj.update_colormap()

            % Add (initially invisible) color bar
            obj.color_bar_handle = colorbar( ...
                'north', 'peer', obj.axes_handle, ...
                'Limits', [0, obj.num_colors], ...
                'FontSize', 8, ...
                'Position', [0.2 0.5 0.6 0.07], ...
                'AxisLocation', 'in', ...
                'Visible', 'off' ...
            );
        end

        function update_colormap(obj)
            s = linspace(0, 1, obj.num_colors)';
            color_map = (1-s) * obj.land_color + s * obj.value_color;
            colormap(obj.axes_handle, color_map);
        end

        function delete(obj)
            disp('Closing figure, axes, and color bar handles')
            if ishandle(obj.fig_handle)
                close(obj.fig_handle)
            end
            if ishandle(obj.axes_handle)
                close(obj.axes_handle)
            end
            if ishandle(obj.color_bar_handle)
                close(obj.color_bar_handle)
            end
        end

        function list_county_names(obj, indices)
            all_indices = 1 : length(obj.counties);
            if nargin < 2
                indices = all_indices;
            end
            mustBeVector(indices)
            mustBeInteger(indices)
            mustBeGreaterThanOrEqual(indices, 1)
            mustBeLessThanOrEqual(indices, length(obj.counties))
            for k = 1 : length(indices)
                i = indices(k);
                fprintf('i = %4d: %s\n', i, obj.counties{i}.name);
                % fprintf('i = %4d: %s\n', i, obj.counties{i}.get_boundaries().NAME);
            end
        end

        function obj = initialize_values(obj, variable_name, init_values)
            mustBeA(variable_name, 'char')
            if nargin < 3
                % If init_values is not given, initialize the value of variable_name to zero for each county
                init_values = zeros(size(obj.counties));
            end
            mustBeVector(init_values)
            if length(init_values) == 1
                init_values = init_values * ones(size(obj.counties));
            end
            assert(length(init_values) == length(obj.counties))
            if ~any(strcmp(variable_name, obj.variable_names))
                obj.variable_names{length(obj.variable_names) + 1} = variable_name;
            end
            for i = 1 : length(obj.counties)
                obj.counties{i} = obj.counties{i}.initialize_values(variable_name, init_values(i));
            end
        end

        function obj = add_values(obj, latitude, longitude, values, variable_name)
            mustBeVector(latitude)
            mustBeVector(longitude)
            mustBeVector(values)
            assert(length(latitude) == length(longitude))
            assert(length(longitude) == length(values))
            mustBeMember(variable_name, obj.variable_names)
            for i = 1 : length(obj.counties)
                obj.counties{i} = obj.counties{i}.add_values( ...
                    latitude, longitude, values, variable_name ...
                );
            end
        end

        function values = get_values(obj, variable_name)
            mustBeMember(variable_name, obj.variable_names)
            values = nan(size(obj.counties));
            for i = 1 : length(obj.counties)
                values(i) = obj.counties{i}.values.(variable_name);
            end
        end

        function to_png(obj, file_name)
            mustBeA(file_name, 'char')
            print(obj.fig_handle, '-dpng', '-r600', file_name);
        end

        function color_bar_to_png(obj, file_name)
            mustBeA(file_name, 'char')
            obj.set_visibility('off')
            obj.color_bar_handle.Visible = 'on';
            print(obj.fig_handle, '-dpng', file_name);
            obj.set_visibility('on')
            obj.color_bar_handle.Visible = 'off';
        end

        function set_visibility(obj, visibility)
            mustBeMember(visibility, {'on', 'off'})
            for i = 1 : obj.num_counties
                obj.counties{i}.set_visibility(visibility)
            end
        end

        function set_colors(obj, color_map_indices)
            mustBeVector(color_map_indices)
            assert(length(color_map_indices) == length(obj.counties))
            for i = 1 : length(obj.counties)
                set_color(obj.counties{i}, color_map_indices(i))
            end
        end

        function focus_on_ercot(obj)
            disp('Setting all counties outside ERCOT invisible')
            fid = fopen(load_config().non_ercot_texas_counties_file, 'r');
            counties_outside_ercot = textscan(fid, '%s', 'Delimiter', {','});
            counties_outside_ercot = counties_outside_ercot{1};
            fclose(fid);
            for i = 1 : length(obj.counties)
                if ~strcmp(obj.counties{i}.boundaries.state, '48') ... % '48' means the county is in Texas
                    || any(strcmp(obj.counties{i}.name, counties_outside_ercot))
                    set([obj.counties{i}.patches{:}], 'Visible', 'off')
                end
            end
        end

        function boundary_shape = get_boundary_shape(obj)
            % Combine all visible counties into a single boundary polyshape object

            % Create a list of all visible counties
            visible_counties = true(size(obj.counties));
            for i = 1 : length(obj.counties)
                visible_counties(i) = ( ...
                    obj.counties{i}.patches{1}.Visible == matlab.lang.OnOffSwitchState.on ...
                );
            end
            idx = find(visible_counties);

            % Turn off the warning, 'Polyshape has duplicate vertices, intersections, or other inconsistencies that may produce inaccurate or unexpected results. Input data has been modified to create a well-defined polyshape.'
            warning('off', 'MATLAB:polyshape:repairedBySimplify')

            % Take the union of all the counties in the list
            boundary_shape = polyshape();
            for k = 1 : length(idx)
                i = idx(k);
                boundary_shape = union( ...
                    boundary_shape, ...
                    polyshape( ...
                        obj.counties{i}.boundaries.longitude, ...
                        obj.counties{i}.boundaries.latitude ...
                    ) ...
                );
                fprintf('%d/%d counties processed\n', k, length(idx));
            end

            % Turn the warning back on
            warning('on', 'MATLAB:polyshape:repairedBySimplify')
        end

        function obj = remove_boundary_data(obj)
            for i = 1 : obj.num_counties
                obj.counties{i} = remove_boundary_data(obj.counties{i});
            end
        end
    end
end
