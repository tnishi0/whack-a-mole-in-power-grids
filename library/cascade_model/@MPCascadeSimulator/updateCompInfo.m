function updateCompInfo(obj)
% Compute the connected components from the B matrix and build lists of the
% swing bus, PV buses, and PQ buses.  This method relies on the fact that
% obj.rmpc has been converted to Matpower's internal indexing (i.e., the
% buses are linearly and consecutively indexed).

% Column indices for Matpower case data
GEN_STATUS = 8; GEN_BUS = 1; PMAX = 9;
BUS_TYPE = 2; REF = 3; ISOLATED = 4; BUS_I = 1;

% Extract the bus and generator data from the Matpower case
bus = obj.rmpc.bus;
gen = obj.rmpc.gen;
nb = size(bus,1);  % Number of buses
ng = size(gen,1);  % Number of generators

% Identify the generators that are ON (i.e., generating power)
on = find(gen(:, GEN_STATUS) > 0);  % Which generators are ON?
gbus = gen(on, GEN_BUS);  % What buses are they located at?

% Compute the connected components of the network using the B matrix
% This step identifies the components (sub-networks) of the entire grid
obj.CompIndex = components(obj, obj.B);  % Get connected components

% Build the Component structure to store information about each component
nc = max(obj.CompIndex);  % Number of components
obj.Component = struct('Status', cell(1,nc), ...
    'in', cell(1,nc), ...
    'ref', cell(1,nc), 'other', cell(1,nc), 'slackgen', cell(1,nc));

% Generate a matrix indicating which buses have active (in-service) generators
Cg = sparse(gen(:, GEN_BUS), (1:ng)', gen(:, GEN_STATUS) > 0, nb, ng);

% Vector indicating if there is an in-service generator at each bus
bus_gen_status = ( Cg * ones(ng,1) > 0 ); 

% Vector of total generation capacities at each bus
bus_pmax = Cg * gen(:,PMAX);

% Loop through each connected component of the network
for i = 1 : nc

    % Set the initial status of each component to ON (assuming it's active initially)
    obj.Component(i).Status = 1;                

    % Identify which buses are in this component
    in = ( obj.CompIndex == i );
    obj.Component(i).in = in;
    
    % Count the number of buses in the component
    obj.Component(i).size = sum(in);
    
    % Check if there are any in-service generators in this component
    c_bus_gen_status = ( in & bus_gen_status );

    % Find the swing bus, which is the reference bus for the component
    ref = find( c_bus_gen_status & bus(:, BUS_TYPE) == REF );

    % If no swing bus is found, assign one based on the bus with the highest total generation
    if isempty(ref)
        if any(c_bus_gen_status) 
            % If there is at least one in-service generator, choose the bus
            % with the largest total generation capacity as the reference bus.
            max_bus_pmax = max(bus_pmax(c_bus_gen_status));
            ref = find(in & bus_pmax == max_bus_pmax, 1, 'first');
            bus(ref, BUS_TYPE) = REF;
            obj.rmpc.bus(ref, BUS_TYPE) = REF;
        else
            % If no bus with an in-service generator is found, set the status
            % of the component to OFF (inactive) and isolate the buses in this component.
            obj.Component(i).Status = 0;
            obj.rmpc.bus(in, BUS_TYPE) = ISOLATED;
            
            % Temporarily set all branches between buses in this component to be out of service
            F_BUS = 1; T_BUS = 2; BR_STATUS = 11; PF = 14; PT = 16;
            bus_i_in = find(in);
            for j = 1 : size(obj.rmpc.branch, 1)
                if any(bus_i_in == obj.rmpc.branch(j, F_BUS)) && ...
                        any(bus_i_in == obj.rmpc.branch(j, T_BUS))
                    obj.rmpc.branch(j, BR_STATUS) = 0;  % Mark branch as out of service
                    obj.rmpc.branch(j, PF) = 0;  % Set power flow to 0
                    obj.rmpc.branch(j, PT) = 0;  % Set power flow to 0
                end
            end
        end
    end
    
    % If a swing bus was not identified, leave the 'ref' and 'slackgen' as empty
    if isempty(ref)
        obj.Component(i).ref = [];
        obj.Component(i).slackgen = [];
    else        
        % For each swing bus, select the generator with the largest capacity as the slack generator
        slackgen = zeros(size(ref));
        for j = 1:length(ref)
            temp = find(gbus == bus(ref(j), BUS_I));
            ind = find(gen(temp, PMAX) == max(gen(temp, PMAX)), 1, 'first');
            slackgen(j) = on(temp(ind(1)));  % Store the linear index of the slack generator
        end
        
        % Save the reference buses and slack generators for this component
        obj.Component(i).ref = ref;
        obj.Component(i).slackgen = slackgen;
    end
    
    % Identify which buses are PV (Voltage-controlled) and PQ (Load) buses
    obj.Component(i).other = ...
        find(in & bus(:, BUS_TYPE) ~= REF);  % All buses in this component except the REF buses

end