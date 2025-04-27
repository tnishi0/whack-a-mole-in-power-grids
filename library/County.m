classdef County
    % Class representing a U.S. county in a CountyMap object
    properties (GetAccess = public, SetAccess = protected)
        name % Name of the county
        boundaries % County boundaries data
        transformed_boundaries % County boundary data after cartgraphic transformation 
        patches % Patch graphics object for the county
        values % Struct containing the variables that can be used to color the county on the map
    end

    methods (Access = public)
        function obj = County(name, boundaries, transformed_boundaries)
            % Constructor:
            % 
            %  obj = County(name, boundaries, transformed_boundaries)
            %
            %  name: Name of the county
            %  boundaries: County boundaries data
            %  transformed_boundaries: County boundary data after cartgraphic transformation 

            if nargin < 3
                obj.transformed_boundaries = [];
            else
                assert( ...
                    isfield(transformed_boundaries, 'latitude') ...
                    && isfield(transformed_boundaries, 'longitude') ...
                )
                assert( ...
                    isvector(transformed_boundaries.latitude) ...
                    && isvector(transformed_boundaries.longitude) ...
                )
                assert( ...
                    length(transformed_boundaries.latitude) ...
                        == length(transformed_boundaries.longitude) ...
                )
                obj.transformed_boundaries = transformed_boundaries;
            end
            if nargin < 2
                obj.boundaries = [];
            else
                assert(isfield(boundaries, 'latitude') && isfield(boundaries, 'longitude'))
                assert(isvector(boundaries.latitude) && isvector(boundaries.longitude))
                assert(length(boundaries.latitude) == length(boundaries.longitude))
                obj.boundaries = boundaries;
            end
            if nargin < 1
                obj.name = [];
            else
                obj.name = name;
            end
        end

        function delete(obj)
            disp('Deleting patches')
            for i = 1 : length(obj.patches)
                delete(obj.patches)
            end
        end

        function obj = draw(obj, axes_handle, cartgram_transform_on)
            % Create cell array of patch objects to draw the county
            if nargin < 3
                cartgram_transform_on = true;
            end
            if cartgram_transform_on
                boundaries = obj.transformed_boundaries;
            else
                boundaries = obj.boundaries;
            end
            k = find(isnan(obj.boundaries.longitude));
            if k(1) ~= 1
                k = [0; k(:)];
            end
            num_patches = length(k) - 1;
            obj.patches = cell(1, num_patches);
            was_hold_off = ~ishold(axes_handle);
            hold(axes_handle, 'on')
            for j = 1 : num_patches
                lat = boundaries.latitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                lon = boundaries.longitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                obj.patches{j} = patch(axes_handle);
                obj.patches{j}.XData = lon;
                obj.patches{j}.YData = lat;
                obj.patches{j}.FaceColor = 'flat';
                obj.patches{j}.CDataMapping = 'direct';
                obj.patches{j}.CData = 1; % Initially set to color map index = 1
                obj.patches{j}.LineWidth = 0.02;
                obj.patches{j}.EdgeColor = 0.7*[1 1 1];
            end
            if was_hold_off
                hold(axes_handle, 'off')
            end
        end

        function obj = update_boundaries(obj, cartgram_transform_on)
            % Update the boundary data in the patch objects
            mustBeMember(cartgram_transform_on, [true, false])
            if cartgram_transform_on
                boundaries = obj.transformed_boundaries;
            else
                boundaries = obj.boundaries;
            end
            k = find(isnan(boundaries.longitude));
            if k(1) ~= 1
                k = [0; k(:)];
            end
            for j = 1 : length(k)-1
                lat = boundaries.latitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                lon = boundaries.longitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                obj.patches{j}.XData = lon;
                obj.patches{j}.YData = lat;
            end
        end

        function obj = initialize_values(obj, variable_name, init_value)
            if nargin < 3
                init_value = 0;
            end
            obj.values.(variable_name) = init_value;
        end

        function obj = add_values(obj, latitude, longitude, values, variable_name)
            % Add the values of the given quantity specified by "variable_name" to the county and 
            % compute the sum of the quantity within the county boundary.
            %
            %   obj = add_values(obj, latitude, longitude, values, variable_name)
            %
            mustBeVector(latitude)
            mustBeVector(longitude)
            mustBeVector(values)
            assert(length(latitude) == length(longitude))
            assert(length(longitude) == length(values))
            assert(isfield(obj.values, variable_name))
            k = find(isnan(obj.boundaries.longitude));
            if k(1) ~= 1
                k = [0; k(:)];
            end
            for j = 1 : length(k)-1
                lat_boundaries = obj.boundaries.latitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                lon_boundaries = obj.boundaries.longitude([k(j)+1:(k(j+1)-1) k(j)+1]);
                in_county = inpolygon(longitude, latitude, lon_boundaries, lat_boundaries);
                obj.values.(variable_name) = obj.values.(variable_name) + sum(values(in_county));
            end
        end

        function set_visibility(obj, visibility)
            mustBeMember(visibility, {'on', 'off'})
            for j = 1 : length(obj.patches)
                obj.patches{j}.Visible = visibility;
            end
        end

        function set_color(obj, color_map_index)
            mustBeInteger(color_map_index)
            for i = 1 : length(obj.patches)
                obj.patches{i}.CData = color_map_index;
            end
        end

        function obj = remove_boundary_data(obj)
            obj.boundaries = [];
            obj.transformed_boundaries = [];
        end
    end
end