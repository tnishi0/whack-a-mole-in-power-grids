function runMPCS_failure(dataName, K, demand_ratio, line_cap_ratio, seed, ffl, toInf)
        
    % Add necessary libraries (ensure paths are correct)
    % Check if 'cascade_model' is in the path
    if ~exist('cascade_model', 'dir')
        addpath('../../library/cascade_model/');
        % Check if the path was successfully added
        if exist('cascade_model', 'dir') == 0
            error('Error: "cascade_model" directory could not be added to the path. Please check the directory.');
        else
            disp('Added "cascade_model" to the path.');
        end
    end
    
    % Check if 'matpower6.0' is in the path
    if ~exist('matpower6.0', 'dir')
        addpath('../../library/matpower6.0/');
        % Check if the path was successfully added
        if exist('matpower6.0', 'dir') == 0
            error('Error: "matpower6.0" directory could not be added to the path. Please check the directory.');
        else
            disp('Added "matpower6.0" to the path.');
        end
    end

    % Default parameters if not provided
    if nargin < 1 || isempty(dataName)
        % Use case3375wp function from Matpower if no dataName is provided
        disp('No dataName provided. Using "case3375wp" from Matpower 6.0.');
        mpc = case3375wp();  % Fetch the case data using the case function
        dataName = 'case3375wp'; % Set dataName as default
    else
        % Check if dataName refers to a Matpower case file (with .mat extension)
        if exist(['data/', dataName, '.mat'], 'file') == 2
            % Load the case data from a .mat file
            try 
                disp(['Loading data for: ', dataName]);
                mpc = load(['data/', dataName, '.mat']); % Load mpc case from .mat file
            catch
                error(['Error: Could not load .mat data file for ', dataName, '. Please check the file path and name.']);
            end
        elseif exist(dataName, 'file') == 2 || exist(dataName, 'builtin') == 4
            % If it's a function name, fetch the data using feval (Matpower case function)
            try
                disp(['Loading data for: ', dataName]);
                mpc = feval(dataName); % Call the function to fetch the case data
            catch
                error(['Error: Could not execute the function for ', dataName, '. Please check the function name and path.']);
            end
        else
            % If neither, provide an error message for invalid data source
            error(['Error: Could not find the data source for ', dataName, '. Please provide a valid .mat file or Matpower case function.']);
        end
    end

    % Assign default values if arguments are not provided
    if nargin < 2, K = 20; end
    if nargin < 3, demand_ratio = 1.2; end
    if nargin < 4, line_cap_ratio = 1.0; end
    if nargin < 5, seed = 1; end
    if nargin < 6, ffl = 0; end
    if nargin < 7, toInf = 0; end

    % Set random seed for reproducibility
    rng(seed);

    % Display initial info
    disp('---------------------------------------------------');
    disp(['Data Name: ', dataName]);
    disp(['Number of Cascade Realizations (K): ', num2str(K)]);
    disp(['Random Number Generator Seed: ', num2str(seed)]);
    disp(['Power Demand Scaling Ratio: ', num2str(demand_ratio)]);
    disp(['Transmission Line Capacity Scaling Ratio: ', num2str(line_cap_ratio)]);
    if ffl == 0
        disp('Failure Line Strategy (ffl): Upgrade all failing lines after each step');
        disp('  - All lines that fail will have their capacity increased immediately after they fail.');
    elseif ffl == 1
        disp('Failure Line Strategy (ffl): Upgrade only the first failing line after each step');
        disp('  - Only the first line to fail in each cascade step will have its capacity increased.');
    end
    if toInf
        disp('Capacity Increasing Method: Set to infinity');
        disp('  - The capacity of the associated line will be set to infinity.');
    else
        disp('Capacity Increasing Method: Upgrade to overloaded capacity');
        disp('  - The capacity of the associated line will be upgraded to its overloaded value + epsilon.');
    end
    disp('---------------------------------------------------');

    % Ensure the 'results' directory exists, or create it
    if ~exist('results', 'dir')
        try
            mkdir('results');
            disp('Directory "results" has been created.');
        catch
            error('Error: Unable to create the "results" directory. Check permissions.');
        end
    end

    % Initialize the Cascade Simulator
    try
        cs = MPCascadeSimulator(mpc, demand_ratio, line_cap_ratio);
    catch
        error('Error: Failed to initialize the MPCascadeSimulator. Check your simulator setup.');
    end

    mpc0 = cs.getMPC0;
    branch = mpc0.branch;
    nl = size(branch, 1);  % number of lines
    caps = zeros(K, nl);   % To store line capacities

    % Loop over realizations
    % Initialize the waitbar before the loop
    h = waitbar(0, 'Progress: 0% done');
    for i = 1:K
        try
            % Update progress
            waitbar(i / K, h, sprintf('Progress: %.2f%% done', (i / K) * 100));

            cs.runCascadeAndUpgrade(i, ffl, toInf, 0);  % Run cascade simulation
            mpc = cs.getMPC0;  % Get the updated MPC
            caps(i, :) = mpc.branch(:, 6);  % Store line capacities
        catch
            warning('Error in realization %d. Skipping this iteration.', i);
            continue;  % Skip this iteration and continue with the next
        end
    end
    % Close the waitbar after the loop
    close(h);

    % File name for result saving
    fileName = sprintf('%s_ffl%d_K%d_demandRatio%.2f_capRatio%.2f_toInf%d_seed%d', ...
        dataName, ffl, K, demand_ratio, line_cap_ratio, toInf, seed);

    % Save results
    try
        save(['results/', fileName, '.mat'], 'cs', 'mpc0', 'caps', '-v7.3');
        disp('Simulation complete. Results saved.');
    catch
        error('Error: Failed to save results. Check file permissions and paths.');
    end
end