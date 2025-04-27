function [overload_line, oPd] = check_overload(obj, alpha)
    % Identifies overloaded lines based on the power flow and a given threshold.
    % Inputs:
    %   alpha: Line outage threshold (0 to 1), lines are overloaded if
    %          their power flow exceeds (1 - alpha) * Pmax.
    %
    % Outputs:
    %   overload_line: Indices of the overloaded lines (excluding out-of-service lines)
    %   oPd: Overload values for each overloaded line

    % Get the Matpower case data from the object (assuming it's stored in obj.rmpc)
    mpc = obj.rmpc;

    % Column indices for Matpower case data
    BR_STATUS = 11;
    Pmax = mpc.branch(:, 6);  % Short-term rating capacity
    PF = abs(mpc.branch(:, 14));  % Power flow on the line

    % Calculate overloads: lines are overloaded if flow exceeds (1-alpha) * Pmax
    Pd = PF - (1 - alpha) * Pmax;
    overload_line = find(Pd > 0);  % Find lines with overloads

    % Filter out out-of-service lines
    overload_line(mpc.branch(overload_line, BR_STATUS) == 0) = [];

    % Return the overload values for the overloaded lines
    oPd = Pd(overload_line);
end