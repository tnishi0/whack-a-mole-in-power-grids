classdef CapacityUpgradeDataStructure
    % Class for storing and processing line capacity upgrade simulation results

    properties (Access = public)
        config = struct();

        % If set to true, the method get_num_lines will count the lines with infinite capacity
        count_lines_inf_cap = false
    end

    properties (Access = private)
        initial_capacitites = struct();
        upgraded_capacities = struct();

        % Matpower constants for bus data
        BUS_I = 1;
        
        % Matpower constants for branch data
        F_BUS = 1;
        T_BUS = 2;
        RATE_A = 6;
    end

    methods (Access = public)
        function obj = CapacityUpgradeDataStructure(config)
            % Constructor
            if nargin < 1
                config = load_config();
            end
            obj.config = config;
            obj = load_initial_capacitites(obj);

            % Initialize upgraded_capacities
            for i = 1 : length(obj.config.strategies)
                strategy = obj.config.strategies{i};
                obj.upgraded_capacities.(strategy) = struct();
                for j = 1 : length(obj.config.ffl)
                    ffl = obj.config.ffl_folders(obj.config.ffl(j));
                    obj.upgraded_capacities.(strategy).(ffl) = struct();
                    for k = 1 : length(obj.config.interconn)
                        interconn = obj.config.interconn{k};
                        obj.upgraded_capacities.(strategy).(ffl).(interconn) = [];
                    end
                end
            end
        end

        function obj = load_initial_capacitites(obj)
            % Load initial line capacity data
            fprintf('Loading initial line capacity data...');
            init_states = get_mpc_init_states(obj.config);
            for i = 1 : length(obj.config.interconn)
                interconn = obj.config.interconn{i};
                obj.initial_capacitites.(interconn) = ...
                    init_states.(interconn).branch(:, obj.RATE_A);
            end
            fprintf(' done\n');
        end

        function obj = save_processed_data(obj, file_name)
            mustBeA(file_name, 'char')
            % Save the processed data to a file
            if nargin < 2
                file_name = 'cap_upg_processed_data.mat';
            end
            fprintf('Processed data saved to "%s"', file_name);
            s.config = obj.config;
            s.initial_capacitites = obj.initial_capacitites;
            s.upgraded_capacities = obj.upgraded_capacities;
            save(file_name, '-struct', 's')
        end

        function obj = load_processed_data(obj, file_name)
            mustBeA(file_name, 'char')
            if nargin < 2
                file_name = 'cap_upg_processed_data.mat';
            end
            s = load(file_name);
            obj.config = s.config;
            obj.initial_capacitites = s.initial_capacitites;
            obj.upgraded_capacities = s.upgraded_capacities;
            fprintf('Loaded processed data from "%s"', file_name);
        end

        function status(obj)
            for i = 1 : length(obj.config.strategies)
                strategy = obj.config.strategies{i};
                fprintf('%s:\n', strategy);
                switch strategy
                    case 'overload_based'
                        ffls = 0;
                    otherwise
                        ffls = obj.config.ffl;
                end
                for j = 1 : length(ffls)
                    ffl = obj.config.ffl_folders(ffls(j));
                    switch strategy
                        case 'overload_based'
                            fprintf(' ----: ');      
                        otherwise  
                            fprintf(' %s: ', ffl);
                    end
                    for k = 1 : length(obj.config.interconn)
                        interconn = obj.config.interconn{k};
                        if isempty(obj.upgraded_capacities.(strategy).(ffl).(interconn))
                            status = ' ';
                        else
                            status = '*';
                        end
                        fprintf('[%s] %s, ', status, interconn);
                    end
                    fprintf('\n');
                end
            end
        end

        function T = results_table(obj)
            row_names = {
                'frequency_based, N^{upg}'
                'frequency_based, C^{upg}'
                'failure_based, N^{upg}'
                'failure_based, C^{upg}'
                'overload_based, N^{upg}'
                'overload_based, C^{upg}'
            };
            column_names = {'All failures', 'First failures'};
            T = table( ...
                'Size', [length(row_names), length(column_names)], ...
                'VariableTypes', {'string', 'string'}, ...
                'RowNames', row_names, ...
                'VariableNames', column_names...
            );
            for i = 1 : length(obj.config.strategies)
                strategy = obj.config.strategies{i};
                switch strategy
                    case 'overload_based'
                        ffls = 0;
                    otherwise
                        ffls = obj.config.ffl;
                end
                for j = 1 : length(ffls)
                    ffl = ffls(j);
                    column_name = column_names{j};
                    row_name = sprintf('%s, N^{upg}', strategy);
                    [num_lines_upg, percentage] = get_num_lines_upg(obj, strategy, ffl);
                    if strcmp(strategy, 'failure_based')
                        num_lines_upg = mean(num_lines_upg);
                        percentage = mean(percentage);
                    end
                    T.(column_name)(row_name) ...
                        = sprintf('%.0f (%.1f%%)', num_lines_upg, percentage);
                    [total_capacity_upgrade, percentage] = get_total_capacity_upgrade(obj, strategy, ffl);
                    if strcmp(strategy, 'failure_based')
                        total_capacity_upgrade = mean(total_capacity_upgrade);
                        percentage = mean(percentage);
                    end
                    row_name = sprintf('%s, C^{upg}', strategy);
                    T.(column_name)(row_name) ...
                        = sprintf('%.2f x 10^6 MVA (%.1f%%)', total_capacity_upgrade / 1e6, percentage);
                end
                T.('First failures')('overload_based, N^{upg}') = '';
                T.('First failures')('overload_based, C^{upg}') = '';                
            end
            if nargout == 0
                disp(T)
                fprintf( ...
                    'Total number of lines: %d, Total initial capacity: %.1f x 10^6 MVA\n', ...
                    obj.get_num_lines(), obj.get_total_initial_capacities() / 1e6 ...
                )
                clearvars T
            end
        end

        function init_caps = get_initial_capacitites(obj, interconn)
            mustBeMember(interconn, obj.config.interconn)
            init_caps = obj.initial_capacitites.(interconn);
        end

        function total = get_total_initial_capacities(obj, interconn)
            if nargin < 2
                total = 0;
                for i = 1 : length(obj.config.interconn)
                    interconn = obj.config.interconn{i};
                    total = total + get_total_initial_capacities(obj, interconn);
                end
            else
                mustBeMember(interconn, obj.config.interconn)
                init_caps = get_initial_capacitites(obj, interconn);
                total = sum(init_caps(~isinf(init_caps)));
            end
        end

        function [num_lines, num_inf_cap] = get_num_lines(obj, interconn)
            if nargin < 2
                num_lines = 0;
                num_inf_cap = 0;
                for i = 1 : length(obj.config.interconn)
                    interconn = obj.config.interconn{i};
                    [num_lines_interconn, num_inf_cap_interconn] = get_num_lines(obj, interconn);
                    num_lines = num_lines + num_lines_interconn;
                    num_inf_cap = num_inf_cap + num_inf_cap_interconn;
                end
            else
                mustBeMember(interconn, obj.config.interconn)
                if obj.count_lines_inf_cap
                    % Lines with infinite capacity are counted
                    num_lines = length(obj.initial_capacitites.(interconn));
                else
                    % Count only the lines with finite initial capacity
                    num_lines = sum(~isinf(obj.initial_capacitites.(interconn)));
                    num_inf_cap = sum(isinf(obj.initial_capacitites.(interconn)));
                end
            end
        end

        function get_num_lines_east_regions(obj)
            % Load the mapping of Eastern regions to AreaName 
            file_name = fullfile( ...
                obj.config.data_folder, ...
                'eastern_regions', ...
                'updated_balance_authorities_sheet.mat' ...
            );
            s = load(file_name, 'Blau');
            balancing_authorities = s.Blau;
            regions = {balancing_authorities.region};

            % Get the Eastern Interconnection data
            mpc = get_mpc_init_states(obj.config).east;
            
            % List all areas that are not yet mapped to any NERC region
            all_area_names = {balancing_authorities.AreaName};
            all_area_names = horzcat(all_area_names{:});
            area_names_not_mapped = setdiff( ...
                unique(mpc.busExtra.AreaName), ...
                all_area_names ...
            );
            fprintf( ...
                'These %d area names are not found in area_to_region mapping:\n', ...
                length(area_names_not_mapped) ...
            );
            disp(area_names_not_mapped)
            
            % Create mapping from AreaName to region name
            area_to_region = dictionary();
            for i = 1 : length(balancing_authorities)
                region = balancing_authorities(i).region;
                for j = 1 : length(balancing_authorities(i).AreaName)
                    area = balancing_authorities(i).AreaName{j};
                    area_to_region(area) = region;
                end
            end

            % Add missing areas to balancing_authorities
            area_to_region('ATSI') = 'RFC';
            area_to_region('BEPC-MISO') = 'MRO';
            area_to_region('DEF') = 'FRCC';
            area_to_region('DEI') = 'RFC';
            area_to_region('DEO&K') = 'RFC';
            area_to_region('EES-EAI') = 'SERC';
            area_to_region('EES-EMI') = 'SERC';
            area_to_region('GMO') = 'SPP';
            area_to_region('JCPL') = 'RFC';
            area_to_region('MIUP') = 'RFC';
            area_to_region('OMUA') = 'SERC';
            area_to_region('SMT') = 'SERC';
            area_to_region('TAP') = 'SERC';

            disp('Area names that were not mapped before are now mapped as follows:')
            for i = 1 : length(area_names_not_mapped)
                area = area_names_not_mapped{i};
                fprintf(' %10s --> %s\n', area, area_to_region(area));
            end

            % Create mapping from bus number to AreaName
            bus_num_to_area = dictionary( ...
                mpc.bus(:, obj.BUS_I), ...
                mpc.busExtra.AreaName ...
            );

            % Map the from- and to-bus of each line (with finite capacity) to a NERC region
            not_inf_cap = ~isinf(mpc.branch(:, obj.RATE_A));
            from_bus_num = mpc.branch(not_inf_cap, obj.F_BUS);
            to_bus_num = mpc.branch(not_inf_cap, obj.T_BUS);
            from_bus_areas = bus_num_to_area(from_bus_num);
            to_bus_areas = bus_num_to_area(to_bus_num);
            from_bus_regions = area_to_region(from_bus_areas);
            to_bus_regions = area_to_region(to_bus_areas);

            % Count the number of lines with infinite capacity
            num_lines_inf_cap = dictionary();
            for i = 1 : length(regions)
                region = regions{i};
                from_bus_regions_all = area_to_region( ...
                    bus_num_to_area(mpc.branch(:, obj.F_BUS)) ...
                );
                num_lines_inf_cap(region) = sum( ...
                    ~not_inf_cap & strcmp(from_bus_regions_all, region) ...
                );
            end

            num_lines = dictionary();
            num_lines_newly_mapped = dictionary();
            for i = 1 : length(balancing_authorities)
                region = balancing_authorities(i).region;
                num_lines(region) = 0;
                num_lines_newly_mapped(region) = 0;
            end
            for i = 1 : length(from_bus_regions)
                area_name = from_bus_areas{i};
                region = from_bus_regions{i};
                if any(strcmp(area_name, area_names_not_mapped))
                    num_lines_newly_mapped(region) = num_lines_newly_mapped(region) + 1;
                end
                num_lines(region) = num_lines(region) + 1;
            end
            
            disp('Total number of lines in each region (including infinite capacity lines):')
            for i = 1 : length(num_lines.keys)
                region = num_lines.keys{i};
                num_lines(region) = num_lines(region) + num_lines_inf_cap(region);
            end
            disp(num_lines)
            count_lines_inf_cap_orig = obj.count_lines_inf_cap;
            obj.count_lines_inf_cap = 1;
            fprintf('Number of lines in west: %d\n', obj.get_num_lines('west'));
            fprintf('Number of lines in texas: %d\n', obj.get_num_lines('texas'));
            fprintf('Total number of lines: %d\n', ...
                sum(num_lines.values) + obj.get_num_lines('west') + obj.get_num_lines('texas') ...
            );
            obj.count_lines_inf_cap = count_lines_inf_cap_orig;
        end

        function [n, percentage] = get_num_lines_upg(obj, strategy, ffl, interconn)
            if strcmp(strategy, 'overload_based') && nargin < 3
                % For overload-based strategy, there is only one case, and the data is store in the field ffl0
                ffl = 0;
            end
            if nargin < 4
                % If interconn is not given, iterate over the interconnections
                n = 0;
                for i = 1 : length(obj.config.interconn)
                    interconn = obj.config.interconn{i};
                    n = n + get_num_lines_upg(obj, strategy, ffl, interconn);
                end
                n_total = get_num_lines(obj);
            else
                mustBeMember(interconn, obj.config.interconn)
                init_caps = get_initial_capacitites(obj, interconn);
                upg_caps = get_upgraded_capacitites(obj, strategy, ffl, interconn);
                if isempty(upg_caps)
                    error( ...
                        'No data on upgraded capacities for %s strategy, ffl = %d, %s interconnection', ...
                        strategy, ffl, interconn ...   
                    )
                end
                num_realizations = size(upg_caps, 2); % = the number of realizations of the simulation for the failure-based strategy
                init_caps = repmat(init_caps, [1, num_realizations]);
                assert(all(size(upg_caps) == size(init_caps)))
                threshold = 0;
                % upg_caps & init_caps are of size (number of lines) x (number of realizations)
                n = sum(upg_caps - init_caps > threshold & ~isinf(init_caps), 1);
                n_total = repmat(get_num_lines(obj, interconn), [1, num_realizations]);
                if nargout > 1
                    percentage = n ./ n_total * 100;
                end
            end

            % Prepare the output
            if nargout == 0 || nargout > 1
                percentage = n ./ n_total * 100;
                if nargout == 0
                    if length(n) == 1
                        fprintf('%d lines (%.1f%%)\n', n, percentage);
                    else
                        for i = 1 : length(n)
                            fprintf('%d: %d lines (%.1f%%)\n', i, n(i), percentage(i));
                        end
                        disp('----------------------------------')
                        fprintf('Average: %.0f lines (%.1f%%)\n', mean(n), mean(percentage));
                    end
                    clear n
                end
            end
        end

        function upg_caps = get_upgraded_capacitites(obj, strategy, ffl, interconn)
            mustBeMember(strategy, obj.config.strategies)
            mustBeMember(ffl, obj.config.ffl)
            mustBeMember(interconn, obj.config.interconn)
            ffl = obj.config.ffl_folders(ffl);
            upg_caps = obj.upgraded_capacities.(strategy).(ffl).(interconn);
        end

        function cap_upg = get_capacity_upgrades(obj, strategy, ffl, interconn)
            mustBeMember(strategy, obj.config.strategies)
            mustBeMember(ffl, obj.config.ffl)
            mustBeMember(interconn, obj.config.interconn)
            upg_caps = get_upgraded_capacitites(obj, strategy, ffl, interconn);
            init_caps = get_initial_capacitites(obj, interconn);
            if isempty(upg_caps)
                error( ...
                    'No data on upgraded capacities for %s strategy, ffl = %d, %s interconnection', ...
                    strategy, ffl, interconn ...   
                )
            end
            init_caps = repmat(init_caps, [1, size(upg_caps, 2)]);
            assert(all(size(upg_caps) == size(init_caps)))
            cap_upg = upg_caps - init_caps;

            % If the initial capacity is inf, then there is no upgrade, so set cap_upg = 0
            cap_upg(isinf(init_caps)) = 0; 
        end

        function [total, percentage] = get_total_capacity_upgrade(obj, strategy, ffl, interconn)
            mustBeMember(strategy, obj.config.strategies)
            if strcmp(strategy, 'overload_based') && nargin < 3
                ffl = 0;
            end
            mustBeMember(ffl, obj.config.ffl)
            if nargin < 4
                total = 0;
                for i = 1 : length(obj.config.interconn)
                    interconn = obj.config.interconn{i};
                    total = total + get_total_capacity_upgrade(obj, strategy, ffl, interconn);
                end
            else
                mustBeMember(interconn, obj.config.interconn)
                total = sum(get_capacity_upgrades(obj, strategy, ffl, interconn), 1);
            end
            if nargout == 0 || nargout == 2
                if nargin < 4
                    init_total_cap = get_total_initial_capacities(obj);
                else
                    init_total_cap = get_total_initial_capacities(obj, interconn);
                end
                init_total_cap = repmat(init_total_cap, size(total));
                percentage = total ./ init_total_cap * 100;
                if nargout == 0
                    if length(total) == 1
                        fprintf( ...
                            'Total capacity upgrade: %.2f x 10^6 MVA (%.1f%%)\n', ...
                            total / 1e6, percentage ...
                        );
                    else
                        disp('Total capacity upgrade (percentage):')
                        for i = 1 : length(total)
                            fprintf( ...
                                ' %3d: %.2f x 10^6 MVA (%4.1f%%)\n', ...
                                i, total(i) / 1e6, percentage(i) ...
                            );
                        end
                        disp(' ------------------------------------')
                        fprintf( ...
                            'Average: %.2f x 10^6 MVA (%4.1f%%)\n', ...
                            mean(total) / 1e6, mean(percentage) ...
                        );
                    end
                    clear total
                end
            end
        end

        function obj = load_data(obj, strategy, ffl, interconn)
            if nargin < 4
                interconns = obj.config.interconn;
            else
                mustBeMember(interconn, obj.config.interconn)
                interconns = {interconn};
            end
            if nargin < 3
                ffls = obj.config.ffl;
            else
                mustBeMember(ffl, obj.config.ffl)
                ffls = ffl;
            end
            if nargin < 2
                strategies = obj.config.strategies;
            else
                mustBeMember(strategy, obj.config.strategies)
                if strcmp(strategy, 'overload_based')
                    disp('Using only ffl = 0, since strategy = "overload_based"')
                    ffls = 0;
                end
                strategies = {strategy};
            end
            for i = 1 : length(strategies)
                for j = 1 : length(ffls)
                    for k = 1 : length(interconns)
                        strategy = strategies{i};
                        ffl = ffls(j);
                        interconn = interconns{k};
                        switch strategy
                            case 'frequency_based'
                                obj = load_data_frequency_based( ...
                                    obj, ffl, interconn ...
                                );
                            case 'failure_based'
                                obj = load_data_failure_based( ...
                                    obj, ffl, interconn ...
                                );
                            case 'overload_based'
                                obj = load_data_overload_based( ...
                                    obj, ffl, interconn ...
                                );
                            otherwise
                                error('Invalid strategy: "%"', strategy)
                        end
                    end
                end
            end
        end

        function county_map = add_capacity_upgrade_data(obj, county_map, strategy, ffl)
            mustBeA(county_map, 'CountyMap')
            mustBeMember(strategy, obj.config.strategies)
            if strcmp(strategy, 'overload_based')
                disp('Using only ffl = 0, since strategy = "overload_based"')
                ffl = 0;
            end
            mustBeMember(ffl, obj.config.ffl)

            county_map = county_map.initialize_values('capacity_upgrades');
            county_map = county_map.initialize_values('initial_capacitites');
            county_map = county_map.initialize_values('num_upgraded_lines');
            county_map = county_map.initialize_values('num_lines');
            init_states = get_mpc_init_states(obj.config);

            disp('Calculating capacity_upgrades, initial_capacitites, and num_upgraded_lines for each county');
            for i = 1 : length(obj.config.interconn)
                interconn = obj.config.interconn{i};
                message = sprintf('%s interconnection', interconn);
                timer = Timer(message);
                cap_upg = mean(obj.get_capacity_upgrades(strategy, ffl, interconn), 2);
                init_caps = obj.get_initial_capacitites(interconn);
                buses = BusLocations(interconn);

                % Ensure that no capacity upgrade values are positive within numerical error and
                % eliminate small negative values
                tolerance = -1e-6;
                assert(all(cap_upg > tolerance))
                cap_upg(cap_upg < 0) = 0;

                % Create lists of initial capacities & capacity upgrades associated with each bus,
                % where half of the capacity of each line is associated with each of the two buses
                % connected by the line.
                tolerance = 0;
                num_lines = length(init_caps);
                assert(num_lines == size(init_states.(interconn).branch, 1)) % Ensure that the number lines match
                cap_upg_buses = zeros(2*num_lines, 1);
                init_caps_buses = zeros(2*num_lines, 1);
                num_upg_lines_buses = zeros(2*num_lines, 1);
                num_lines_buses = zeros(2*num_lines, 1);
                latitude = zeros(2*num_lines, 1);
                longitude = zeros(2*num_lines, 1);
                for j = 1 : num_lines
                    % 1/2 contributes to the from-bus
                    bus_number = init_states.(interconn).branch(j, obj.F_BUS);
                    latitude(2*j - 1) = buses.latitude(bus_number);
                    longitude(2*j - 1) = buses.longitude(bus_number);
                    if obj.count_lines_inf_cap
                        num_lines_buses(2*j - 1) = 0.5;
                    end
                    if ~isinf(init_caps(j))
                        cap_upg_buses(2*j - 1) = cap_upg(j) / 2;
                        init_caps_buses(2*j - 1) = init_caps(j) / 2;
                        if ~obj.count_lines_inf_cap
                            num_lines_buses(2*j - 1) = 0.5;
                        end
                        if cap_upg(j) > tolerance
                            num_upg_lines_buses(2*j - 1) = 0.5;
                        end
                    end

                    % 1/2 contributes to the to-bus
                    bus_number = init_states.(interconn).branch(j, obj.T_BUS);
                    latitude(2*j) = buses.latitude(bus_number);
                    longitude(2*j) = buses.longitude(bus_number);
                    if obj.count_lines_inf_cap
                        num_lines_buses(2*j) = 0.5;
                    end
                    if ~isinf(init_caps(j))
                        cap_upg_buses(2*j) = cap_upg(j) / 2;
                        init_caps_buses(2*j) = init_caps(j) / 2;
                        if ~obj.count_lines_inf_cap
                            num_lines_buses(2*j) = 0.5;
                        end
                        if cap_upg(j) > tolerance
                            num_upg_lines_buses(2*j) = 0.5;
                        end
                    end
                end
                
                % Add these values to the CountyMap object
                county_map = county_map.add_values(latitude, longitude, cap_upg_buses, 'capacity_upgrades');
                county_map = county_map.add_values(latitude, longitude, init_caps_buses, 'initial_capacitites');
                county_map = county_map.add_values(latitude, longitude, num_upg_lines_buses, 'num_upgraded_lines');
                county_map = county_map.add_values(latitude, longitude, num_lines_buses, 'num_lines');

                timer.stop();
            end
        end
    end

    methods (Access = private)

        function obj = load_data_frequency_based(obj, ffl, interconn)
            % Read and process the raw simulation results files for the frequency-based strategy
            mustBeMember(ffl, obj.config.ffl)
            mustBeMember(interconn, obj.config.interconn)
            fprintf('Loading capacity data for frequency-based strategy');
            fprintf(', ffl = %d, %s interconnection\n', ffl, interconn);

            data_folder = obj.config.frequency_based_results_folder;
            ffl_folder = obj.config.ffl_folders(ffl);
            file_names = ...
                obj.config.data_source_paths.frequency_based.(ffl_folder).(interconn);

            if ~iscell(file_names)
                file_names = {file_names};
            end

            upg_caps = cell(1, length(file_names));
            for i = 1 : length(file_names)
                file_name = file_names{i};
                assert(ischar(file_name))
                
                fprintf(' %d: Loading from "%s"...', i, file_name);
                data_file = fullfile( ...
                    data_folder, ...
                    ffl_folder, ...
                    file_name ...
                );
                t1 = toc;
                s = load(data_file, 'csc');
                fprintf(' done in %.1f sec\n', toc - t1);
                
                % Ensure that the initial line capacities in mpc0 from s.csc{1} (which are used in the first
                % upgrade iteration) match that saved in obj.initial_capacitites
                init_caps = s.csc{1}.getMPC0().branch(:, obj.RATE_A);
                assert( ...
                    isvector(init_caps) && ...
                    length(init_caps) == length(obj.initial_capacitites.(interconn)) && ...
                    all(init_caps == obj.initial_capacitites.(interconn)) ...
                )
                
                % For the line capacities after m upgrade iterations, use mpc0 from s.csc{m+1}, but if it is empty,
                % use mpc0 from s.csc{iter}, where iter is the largest iter for which s.csc{iter} is not empty.
                % s.csc{iter} would be empty if the simulation did not reach that iteration.
                m = obj.config.data_source_paths.frequency_based.(ffl_folder).m;
                iter = m + 1;
                while isempty(s.csc{iter}) && iter >= 1
                    iter = iter - 1;
                end
                if iter == 0
                    error('iter = 0!')
                end
                upg_caps{i} = s.csc{iter}.getMPC0().branch(:, obj.RATE_A);
                assert( ... % Ensure consistency
                    isvector(upg_caps{i}) && ...
                    length(upg_caps{i}) == length(obj.initial_capacitites.(interconn)) ...
                )
            end
            
            % For the Eastern interconnection, take the maximum capacity for each
            % line over the 6 region_prefixes
            obj.upgraded_capacities.frequency_based.(ffl_folder).(interconn) ...
                = max(cell2mat(upg_caps), [], 2);
        end

        function obj = load_data_failure_based(obj, ffl, interconn)
            % Read and save the processed simulation results files for the failure-based strategy
            mustBeMember(ffl, obj.config.ffl)
            mustBeMember(interconn, obj.config.interconn)
            fprintf('Loading capacity data for failure-based strategy')
            fprintf(', ffl = %d, %s interconnection\n', ffl, interconn);
            ffl = obj.config.ffl_folders(ffl);
            data_file = fullfile( ...
                obj.config.failure_based_results_folder.(ffl), ...
                obj.config.data_source_paths.failure_based.(ffl).(interconn) ...
            );
            s = load(data_file, 'caps_it');
            upg_caps = (s.caps_it).';
            assert(size(upg_caps, 1) == length(obj.initial_capacitites.(interconn))) % Ensure consistency
            obj.upgraded_capacities.failure_based.(ffl).(interconn) = upg_caps;
        end

        function obj = load_data_overload_based(obj, ffl, interconn)
            % Read and process the raw simulation results files for the overload-based strategy
            fprintf('Loading capacity data for overload-based strategy')
            fprintf(', ffl = %d, %s interconnection\n', ffl, interconn);
            ffl = obj.config.ffl_folders(ffl);
            data_folder = obj.config.overload_based_results_folder;
            data_file_names = obj.config.data_source_paths.overload_based.(interconn);
            cases = {};
            % Load the data
            for i = 1 : length(data_file_names)
                data_file = fullfile(data_folder, data_file_names{i});
                fprintf(' Loading "%s"... ', data_file_names{i});
                t0 = cputime;
                s = load(data_file, 'cases');
                cases = cat(1, cases, s.cases);
                fprintf('done in %.1f sec\n', cputime - t0);
            end
            % Compute the maximum overload for each line
            fprintf(' Computing the maximum overload for each line... ');
            t0 = cputime;
            max_overload = zeros(length(obj.initial_capacitites.(interconn)), 1);
            for i = 1 : length(cases)
                % Each cases{i} is a vector of size (number of overloaded lines) x 2
                % In the first column are line indices (as in branch) 
                idx = cases{i}(:, 1);
                for k = 1 : length(idx)
                    if max_overload(idx(k)) < cases{i}(k, 2)
                        max_overload(idx(k)) = cases{i}(k, 2);
                    end
                end
            end
            obj.upgraded_capacities.overload_based.(ffl).(interconn) ...
                = get_initial_capacitites(obj, interconn) + max_overload;
            fprintf('done in %.1f sec\n', cputime - t0);
        end
    end

end