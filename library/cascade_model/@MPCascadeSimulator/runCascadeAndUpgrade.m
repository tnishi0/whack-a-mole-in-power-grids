function runCascadeAndUpgrade(obj, i, ffl, toInf, dispon)
    % Run a cascade simulation and upgrade line capacities based on cascade results.
    % Parameters:
    %   i        - Simulation index (default: 0)
    %   ffl      - If true, upgrade only the first failing line (default: 1)
    %   toInf    - If true, increase line capacity to infinity (default: 1)
    %   dispon   - If true, display simulation progress (default: 1)

    % Set defaults if not provided
    if nargin < 2, i = 0; end
    if nargin < 3, ffl = 1; end
    if nargin < 4, toInf = 1; end
    if nargin < 5, dispon = 1; end

    % Run the cascade event simulation
    runCascadeEvent(obj);

    % Extract the subset of failed lines (after triggering phase)
    subset = nonzeros(obj.Proc(obj.ntrig + 1:end));

    if ~isempty(subset)
        % If only the first failing line is upgraded, limit the subset to the first line
        if ffl
            subset = subset(1);
        end

        % Determine the line capacity increment method
        if toInf
            incBy = inf; % Increase capacity to infinity
        else
            co = obj.getCapacityOverload; % Get the overloaded capacity values
            incBy = co(subset); % Overload increment
        end

        % Upgrade line capacities by the increment amount
        obj.rmpc0.branch(subset, 6:8) = obj.rmpc0.branch(subset, 6:8) + incBy + 0.1;
    end

    % Display progress information if 'dispon' is enabled
    if dispon
        fprintf('Simulation %6d: ', i);
        for j = 1 : obj.ntrig + 3
            fprintf('%6d ', full(obj.Proc(j)));
        end
        fprintf('(%d primary failures)\n', sum(obj.Proc > 0) - obj.ntrig);
    end
end