function step(obj)
    % This method implements a single step of the cascading failure process.
    % It updates the system state, calculates power flow, adjusts generation, 
    % and tracks failures until the cascade is stopped.
    
    % Increment the time step by 1.
    obj.t = obj.t + 1;
    
    % Update the B matrix and connected component information.
    updateMatrixB(obj);    % Update matrix B for power flow calculations
    updateCompInfo(obj);    % Recompute connected components after each failure
    
    % Compute power flow across the system using DC power flow method.
    computePowerFlow(obj);
    
    % Adjust generation at slack buses and scale loads uniformly across components.
    adjustPowerInComp(obj);
    
    % Update the B matrix again after load adjustments.
    updateMatrixB(obj);
    
    % Recompute power flow after the updates.
    computePowerFlow(obj);
    
    % Generate indices of overloaded transmission lines.
    [ovl, oPd] = check_overload(obj, 0);    % Check for overloaded lines
    
    % Store the overload data in the object's state for later retrieval
    obj.ovl = ovl;  % Store overloaded lines
    obj.oPd = oPd;  % Store overload power demand values

    % Update the capacity overload for the overloaded lines.
    idx = obj.capOvl(ovl) < oPd;  
    obj.capOvl(ovl(idx)) = oPd(idx);   % Update overload capacity based on current flow
    
    % Stop the cascade if no lines are overloaded.
    if isempty(ovl)
        obj.Status = MPCasSimStatus.Stopped;    % Set the status to 'Stopped'
        return;    % End the cascade process
    end
    
    % Determine and implement the next failure event based on overloaded lines.
    nextLineFailure(obj, ovl);

end