function l = increaseCap(obj, subset, incBy)
    % Increase the capacity of given subset by incBy for the specified lines
    % Correct resistance and reactance accordingly for the given subset (vulnerable set).
    %
    % Input:
    %   obj     - The system object containing power grid data.
    %   subset  - The indices of the branches (lines) to increase the capacity.
    %   incBy   - The value by which to increase the capacity of the lines (optional).
    %
    % Output:
    %   l       - The number of lines for which the capacity was increased.

    % Error handling: Ensure that 'subset' is not empty
    if isempty(subset)
        disp('No lines selected for capacity increase.');
        return;  % Exit the function if no lines are selected
    end

    % Error handling: Ensure that 'subset' contains valid indices for the branch data
    if any(subset < 1) || any(subset > size(obj.rmpc0.branch, 1))
        error('One or more line indices in the subset are out of range.');
    end

    % Default behavior: If no increment value is provided, use current overload values
    if nargin < 3
        co = obj.getCapacityOverload;
        incBy = co(subset);  % Overload values for the specified subset of lines
    end

    l = length(subset);  % Get the number of lines in the subset

    % Save the old capacities for updating resistance and reactance below
    % cap_old = obj.rmpc0.branch(subset, 6);

    % Increase the capacity of given lines by the specified increment
    obj.rmpc0.branch(subset, 6:8) = obj.rmpc0.branch(subset, 6:8) + incBy + 0.1;
    disp(['Successfully increased the capacity of ', num2str(l), ' vulnerable lines.']);

    % Testing consistency: Update resistance and reactance based on the new capacities
    % obj.rmpc0.branch(subset, 3:4) = obj.rmpc0.branch(subset, 3:4) .* (cap_old ./ obj.rmpc0.branch(subset, 6));
end