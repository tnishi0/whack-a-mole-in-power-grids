function prepareInitialState(obj, dataset, dispon)
% Prepare the initial state of the system as obj.rmpc.
%
% This function loads the power grid data, modifies generators and buses,
% scales the demand and generation, and ensures the initial state is ready
% for cascading failure simulations. It also computes the DC power flow
% and adjusts line capacities.

% Column indices for Matpower case data.
BUS_I = 1; BUS_TYPE = 2; PD = 3; QD = 4; PV = 2; REF = 3;
PG = 2; GEN_STATUS = 8; PMAX = 9;
RATE_A = 6; PF = 14; F_BUS = 1; T_BUS = 2; QT = 17;

if nargin < 3
    dispon = 0;
end

% Load the Matpower case data.
if ischar(dataset)
    obj.MPCaseFileName = dataset;
    obj.rmpc = loadcase(obj.MPCaseFileName);
else
    obj.MPCaseFileName = '';
    obj.rmpc = dataset;
end
if dispon
    disp('Matpower case data loaded:')
    disp(obj.rmpc)
end

% Remove the generator cost data (not needed when using DC power flow).
if isfield(obj.rmpc, 'gencost')
    obj.rmpc = rmfield(obj.rmpc, 'gencost');
    if dispon
        disp('Field "gencost" removed')
    end
end

% Copy the data in obj.rmpc to local variables.
gen = obj.rmpc.gen;
bus = obj.rmpc.bus;

% If there are generators whose Pmax = 0, set the generator to be
% not-in-service.
ix = (gen(:, PMAX) == 0);
if ~isempty(ix)
    gen(ix, GEN_STATUS) = 0; % set not-in-service
end
if dispon
    fprintf('%d generators with Pmax = 0 removed\n', sum(ix))
end

% Disconnect the generators whose Pmax > 9990 (in particular, those with
% Pmax = 9999) by setting them to be not-in-service.
ix = (gen(:, PMAX) > 9990);  % Hardcoded value for large PMAX (9990)
gen(ix, GEN_STATUS) = 0; % 
if dispon
    fprintf('%d generators with Pmax > 9990 removed\n', sum(ix))
end

% Adjust the generator capacity (increase by 10%) if the power output is
% larger than that, i.e. Pmax < PG (to avoid the violation).
ix = (gen(:, PG) > gen(:, PMAX));
gen(ix, PMAX) = gen(ix, 2) * 1.1;
if dispon
    fprintf('%d generator capacities Pmax < PG adjusted to Pmax = PG * 1.1\n', sum(ix))
end

% Replace each negative load buses with a PV bus and a new generator.
bus_list = bus(:, BUS_I);
gbus = bus_list(bus(:, PD) < 0); % list of buses with negative power demand
NewG = zeros(length(gbus), size(gen, 2));
for i = 1 : length(gbus)
    u = find(bus_list == gbus(i));
    Pd = bus(u, PD);
    Qd = bus(u, QD);
    if bus(u, BUS_TYPE) ~= REF
        bus(u, BUS_TYPE) = PV;
    end
    bus(u, PD) = 0;
    bus(u, QD) = 0;
    new_gen = zeros(1, size(gen, 2));
    new_gen(1) = gbus(i); % bus number
    new_gen(2) = -1 * Pd; % real power output (MW)
    new_gen(3) = -1 * Qd; % reactive power output (MVAr)
    new_gen(4) = abs(new_gen(3)); % maximum reactive power output (MVAr)
    new_gen(5) = -1*abs(new_gen(3)); % minimum reactive power output (MVAr)
    new_gen(6) = 1; % voltage magnitude setpoint (p.u)
    new_gen(7) = obj.rmpc.baseMVA; % total MVA base of the machine
    new_gen(8) = 1; % machine status: 1=connected
    new_gen(9) = abs(Pd) * 1.1; % max real power (MVA)
    new_gen(10) = 0; % minimum real power output (MW)
    new_gen(11:end) = 0;
    NewG(i, :) = new_gen;
end
gen = [gen; NewG];

if dispon
    fprintf('%d negative load buses converted to PV bus connected to a generator.\n', length(gbus));
end

% Remove the lines that are not in service
obj.rmpc.branch(obj.rmpc.branch(:, 11) == 0, :) = [];

% Add zero columns to branch for flows if needed
if size(obj.rmpc.branch, 2) < QT
    obj.rmpc.branch = [obj.rmpc.branch, zeros(size(obj.rmpc.branch, 1), QT - size(obj.rmpc.branch, 2))];
end

% Scale the demand and generation across the whole system by the given
% ratio (obj.DemandRatio), adjusting the generator capacity accordingly.
bus(:, 3:4) = bus(:, 3:4) * obj.DemandRatio;
gen(:, 2) = gen(:, 2) * obj.DemandRatio;
ix = find(gen(:, 2) > gen(:, 9));
if ~isempty(ix)
    gen(ix, 9) = gen(ix, 2);
end

% Scale the line capacities.
obj.rmpc.branch(:, 6:8) = obj.rmpc.branch(:, 6:8) * obj.LineCapRatio;

% Copy the modified data back to obj.rmpc.
obj.rmpc.gen = gen;
obj.rmpc.bus = bus;

if dispon
    % Convert to Matpower's internal indexing.
    fprintf('Converted to Matpower''s internal indexing\n\n')
end

obj.rmpc = ext2int(obj.rmpc);

% Compute the B matrix and the Pbus vector for DC power flow equation.
updateMatrixB(obj)

% Compute the connected components and choose a swing bus for each.
updateCompInfo(obj)

% Calculate the power flow.
computePowerFlow(obj)

% Adjust if the network is disconnected.     
adjustPowerInComp(obj)

% Update the B matrix and the Pbus vector.
updateMatrixB(obj)

% Calculate the power flow again.
computePowerFlow(obj)

% Adjust the line capacities (RATE_A) to make sure the flow over the lines
% is within 95% of the capacities.
ovl = check_overload(obj, 0.05);  % Hardcoded value for overload (5%)
if ~isempty(ovl)
    ovl_RATE_A = obj.rmpc.branch(ovl, RATE_A);
    obj.rmpc.branch(ovl, RATE_A) = abs(obj.rmpc.branch(ovl, PF)) / 0.95;
    disp('Capacity increased to ensure power flow is within 95% of capacity:')
    for i = 1:length(ovl)
        fprintf('  line[%d]: bus[%d]--bus[%d], |PF| = %gMW, RATE_A = %g -> %gMW\n', ...
            ovl(i), obj.rmpc.branch(ovl(i), F_BUS), obj.rmpc.branch(ovl(i), T_BUS), ...
            abs(obj.rmpc.branch(ovl(i), PF)), ovl_RATE_A(i), obj.rmpc.branch(ovl(i), RATE_A))
    end
    fprintf('\n');
end

% Update the B matrix and the Pbus vector.
updateMatrixB(obj)

% Calculate the power flow again.       
computePowerFlow(obj)