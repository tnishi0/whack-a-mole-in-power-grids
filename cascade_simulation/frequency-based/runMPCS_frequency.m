function runMPCS_frequency(dataName, NofInc, K, demand_ratio, line_cap_ratio, threshold, seed, ffl, toInf)
    
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
        if exist(['data/', dataName, '.mat'], 'file')
            % Load the case data from a .mat file
            try 
                disp(['Loading data for: ', dataName]);
                mpc = load(['data/', dataName, '.mat']); % Load mpc case from .mat file
            catch
                error(['Error: Could not load .mat data file for ', dataName, '. Please check the file path and name.']);
            end
        elseif exist(dataName, 'file') == 2 || exist(dataName, 'file') == 4
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
    if nargin < 2, NofInc = 1; end
    if nargin < 3, K = 30; end
    if nargin < 4, demand_ratio = 1.2; end
    if nargin < 5, line_cap_ratio = 1.0; end
    if nargin < 6, threshold = 1; end
    if nargin < 7, seed = 1; end
    if nargin < 8, ffl = 0; end
    if nargin < 9, toInf = 0; end

    % Set random seed for reproducibility
    rng(seed);

    % Display initial simulation setup info
    disp('---------------------------------------------------');
    disp(['Data Name: ', dataName]);
    disp(['Number of Planned Upgrade Iterations (NofInc): ', num2str(NofInc)]);
    disp('Note: The simulation will stop early if no vulnerable lines are found.');
    disp(['Number of Cascade Realizations (K): ', num2str(K)]);
    disp(['Power Demand Scaling Ratio (demand_ratio): ', num2str(demand_ratio)]);
    disp(['Transmission Line Capacity Scaling Ratio (line_cap_ratio): ', num2str(line_cap_ratio)]); 
    disp(['Vulnerable Line Failure Threshold: ', num2str(threshold)]);
    disp(['Random Number Generator Seed: ', num2str(seed)]);
    % Clarify ffl (Failure Line Strategy)
    if ffl == 0
        disp('Failure Line Strategy (ffl): Upgrade all vulnerable lines');
        disp('  - All failing lines above the threshold will have their capacity increased.');
    elseif ffl == 1
        disp('Failure Line Strategy (ffl): Upgrade lines failing first in at least k cascades');
        disp('  - Only the lines that fail first in at least k cascades will have their capacity increased.');
    end
    if toInf
        disp('Capacity Increasing Method: Set to infinity for vulnerable lines.');
        disp('  - Overloaded lines will have their capacity increased to infinity.');
    else
        disp('Capacity Increasing Method: Upgrade to overloaded capacity for vulnerable lines.');
        disp('  - The capacity of overloaded lines will be increased to their current overload value plus a small epsilon.');
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

    % Loop over realizations
    % Initialize the waitbar before the loop
    h = waitbar(0, 'Progress: 0% done');
    for i = 1:NofInc+1
        try
            % Update progress
            waitbar(i / (NofInc+1), h, sprintf('Progress: %.2f%% done', (i / (NofInc+1)) * 100));

            % Clear history and run multiple cascade events
            cs.clearHistory
            cs.runMultipleCascadeEvents(K, 1);

            % Copy the state of the simulation for storage
            cs_copy = copy(cs);
            csc{i} = cs_copy;  % Store the copy of the simulation

            % Get first failing lines or all failing lines based on ffl
            if ffl == 1
                fl = cs.getFirstFails;
                [u, v] = hist(fl, 1:max(fl));
            elseif ffl == 0
                wfl = cs.getHistoryFailureSeq;
                wfl = nonzeros(wfl(:, 4:end));
                [u, v] = hist(wfl, 1:max(wfl));
            end

            % Find the lines with failure counts above the threshold
            subset = find(u > threshold);

            % Increase the capacity of the selected lines
            if toInf
                l = cs.increaseCap(subset, inf);  % Increase capacity to infinity
            else
                l = cs.increaseCap(subset);  % Increase capacity by overloaded value
            end

            % Stop if no lines were increased
            if l == 0
                break;
            end
        catch
            warning('Error in realization %d. Skipping this iteration.', i);
            continue;  % Skip this iteration and continue with the next
        end
    end


    % Close the waitbar after the loop
    close(h);

    % File name for result saving
    fileName = sprintf('%s_ffl%d_K%d_NofInc%d_demandRatio%.2f_capRatio%.2f_threshold%d_seed%d', ...
        dataName, ffl, K, NofInc, demand_ratio, line_cap_ratio, threshold, seed);

    % Save results
    try
        save(['results/', fileName, '.mat'], 'csc', '-v7.3');
        disp('Simulation complete. Results saved.');
    catch
        error('Error: Failed to save results. Check file permissions and paths.');
    end
end