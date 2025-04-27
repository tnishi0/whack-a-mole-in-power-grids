function cutoff_line(obj, cutl)
    % Cut off a given set of lines (cutl) of the system.

    % Validate input: Ensure cutl is not empty and contains valid indices
    if isempty(cutl)
        error('No lines provided to cut off.');
    end
    num_lines = size(obj.rmpc.branch, 1);
    if any(cutl < 1 | cutl > num_lines)
        error('Some indices in cutl are out of range.');
    end

    % Set the lines to be not in-service.
    obj.rmpc.branch(cutl, 11) = 0;

    % Record the failure.
    obj.Outlines(cutl) = 0;

    % Remove the associated branch shunt conductances if 'branch_shunts' exists
    if isfield(obj.rmpc, 'branch_shunts')
        % For each line in cutl, find the affected buses
        for i = 1:length(cutl)
            % Find the buses connected to the line
            inbf = find(obj.rmpc.bus(:,1) == obj.rmpc.branch(cutl(i), 1));  % From bus
            inbt = find(obj.rmpc.bus(:,1) == obj.rmpc.branch(cutl(i), 2));  % To bus
            
            % Update the bus shunts
            obj.rmpc.bus(inbf, 5) = obj.rmpc.bus(inbf, 5) - obj.rmpc.branch_shunts.F_GS(cutl(i));
            obj.rmpc.bus(inbt, 5) = obj.rmpc.bus(inbt, 5) - obj.rmpc.branch_shunts.T_GS(cutl(i));
        end
    end
end