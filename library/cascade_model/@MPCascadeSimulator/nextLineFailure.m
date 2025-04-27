function nextLineFailure(obj, ovl)
    % Determine and implement the next failure.
    
    % Column indices for Matpower case data
    RATE_A = 6;
    PF = 14;
    
    % The power flow, rating, and temperature for each line
    P = obj.rmpc.branch(ovl, PF);
    R = obj.rmpc.branch(ovl, RATE_A);
    T = obj.T(ovl);
    
    % Calculate the time it takes for overload lines to reach their critical temperature.
    % Ensure no negative values are used in logarithm (avoid physical inconsistencies).
    tel = -log( (R.^2 - P.^2) ./ (T - P.^2) );
    
    % Safety check: If any lines reach critical temperature too quickly, report error.
    if any(tel < -1e5)
        error('Time till next failure <= 0 for some lines.');
    end
    
    % Select the line that reaches critical temperature first.
    [t, i] = min(tel);
    obj.Proc_time(obj.ntrig + obj.t) = t;  % The time till failure
    
    % Update the temperature of all lines.
    P = obj.rmpc.branch(:, PF);
    obj.T = exp(-t) * (obj.T - P.^2) + P.^2;  % Exponential update of temperatures
    
    % Cut off the line (set it as failed).
    cutoff_line(obj, ovl(i))
    
    % Record the line failure in the failure sequence.
    j = find(obj.Proc == 0, 1);  % Find the next available failure slot
    obj.Proc(j) = ovl(i);  % Record the failure line
end