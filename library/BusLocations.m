classdef BusLocations
    % Class object for updating the Latitude and longitude of buses in a system.

    properties (GetAccess = public, SetAccess = private)
        interconnection
        data_file
        latitude % dictionary: bus number --> latitude
        longitude % dictionary: bus number --> longitude
        tolerance = 1e-6
        verbose
    end

    properties (Access = private)
        bus_num_data_type = 'uint32'
        geo_loc = cell(1, 3)
    end

    methods (Access = public)
        function obj = BusLocations(interconn, verbose)
            if nargin < 2
                verbose = false;
            end
            obj.verbose = verbose;

            config = load_config();
            if nargin < 1
                interconn = config.interconn{1};
            end
            mustBeMember(interconn, config.interconn)
            obj.interconnection = interconn;

            if obj.verbose
                timer = Timer('Loading the data file');
            end

            % Load the bus location data
            data_file_name = strcat(interconn, '_buses.csv');
            data_folder = config.geo_loc_data_folder;
            obj.data_file = fullfile(data_folder, data_file_name);
            opt = detectImportOptions( ...
                obj.data_file, ...
                'RowNamesColumn', 0, ...
                'NumHeaderLines', 1, ...
                'ReadRowNames', 1 ...
            );
            opt.VariableTypes{1} = obj.bus_num_data_type;
            T = readtable(obj.data_file, opt);

            % Create bus number to geo location mapping for each interconenction
            obj.latitude = dictionary(T.Number, T.SubLatitude);
            obj.longitude = dictionary(T.Number, T.SubLongitude);
            
            if obj.verbose
                timer.stop()
            end
        end

        function h = plot(obj, axes_handle)
            if nargin < 2
                axes_handle = gca;
            end
            assert(ishandle(axes_handle))
            h = plot(axes_handle, ...
                obj.longitude.values(), obj.latitude.values(), '.' ...
            );
            axis(axes_handle, 'equal')
            title(axes_handle, strcat(obj.interconnection, ' inteconnection'))
            xlabel(axes_handle, 'Longitude')
            ylabel(axes_handle, 'Latitude')
            if nargout == 0
                clear h
            end
        end

        function to_png(obj, file_name)
            mustBeA(file_name, 'char')
            fig_handle = figure();
            axes_handle = axes(fig_handle);
            plot(obj, axes_handle);
            print(fig_handle, '-dpng', file_name)
            delete(fig_handle)
        end
    end
end
