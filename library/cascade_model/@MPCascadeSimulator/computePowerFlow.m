function computePowerFlow(obj)
    % Computes the DC power flow solution on each connected component.

    % Column indices for Matpower case data
    VM = 8; VA = 9;
    GEN_STATUS = 8; PG = 2; QG = 3;
    QF = 15; QT = 17; PF = 14; PT = 16; BR_STATUS = 11;

    % Copy data from obj to local variables.
    B = obj.B;
    [baseMVA, bus, gen, branch] = deal(obj.rmpc.baseMVA, obj.rmpc.bus, obj.rmpc.gen, obj.rmpc.branch);

    % Vector of logical variables indicating which generators are ON
    on = find(gen(:, GEN_STATUS) > 0);

    % Va0 is the initial voltage angle (in radians) for all buses
    Va0 = bus(:, VA) * (pi / 180);  % Convert initial voltage angles from degrees to radians
    Va = Va0;  % Initialize the voltage angles for the power flow calculation

    % Find active components
    active_components = [obj.Component(:).Status];  % Logical array of active components
    ci = find(active_components);  % Indices of active components

    % For each component whose status is ON:
    for k = 1 : length(ci)
        i = ci(k);
        ref = obj.Component(i).ref;
        slackgen = obj.Component(i).slackgen;
        
        % Compute the DC power flow within the component (if the component size is > 1)
        if obj.Component(i).size > 1
            ix = obj.Component(i).other;
            Va(ix) = B(ix, ix) \ (obj.Pbus(ix) - B(ix, ref) * Va0(ref));  % Solve for Va of non-ref buses
        end
        
        % Update Pg for the slack generators
        slack_power_adjustment = (B(ref, :) * Va - obj.Pbus(ref)) * baseMVA;
        gen(slackgen, PG) = gen(slackgen, PG) + slack_power_adjustment;  % Update slack generator power
    end

    % Update data matrices with solution
    branch(:, [QF, QT]) = zeros(size(branch, 1), 2);  % Set zero flow for all branches
    branch(:, PF) = (obj.Bf * Va + obj.Pfinj) * baseMVA;  % Compute power flow
    branch(:, PT) = -branch(:, PF);  % Reverse power flow for the target buses
    bus(:, VM) = ones(size(bus, 1), 1);  % Set voltage magnitude to 1 (p.u.)
    bus(:, VA) = Va * (180 / pi);  % Convert voltage angles back to degrees

    % Zero out result fields of out-of-service generators and branches
    gen(~on, [PG, QG]) = 0;  % Set power outputs to zero for generators that are offline
    branch(branch(:, BR_STATUS) == 0, [PF, QF, PT, QT]) = 0;  % Zero out flows for disconnected branches

    % Update obj.rmpc
    [obj.rmpc.bus, obj.rmpc.gen, obj.rmpc.branch] = deal(bus, gen, branch);
end