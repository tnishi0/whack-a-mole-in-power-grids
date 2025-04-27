function runMPCS_overload(dataName, K, demand_ratio,line_cap_ratio,  seed)

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
        % Try to load the case data from a .mat file
        try
            if exist(['data/', dataName, '.mat'], 'file')
                disp(['Loading data for: ', dataName]);
                mpc = load(['data/', dataName, '.mat']); % Load mpc case from .mat file
            else
                error('FileNotFound');  % Trigger error if .mat file doesn't exist
            end
        catch
            % If the .mat file loading fails, check if it's a function name
            try
                % If it's a function name, fetch the data using feval (Matpower case function)
                if exist(dataName, 'file') == 2 || exist(dataName, 'file') == 4
                    disp(['Loading data for: ', dataName]);
                    mpc = feval(dataName); % Call the function to fetch the case data
                else
                    error('InvalidFunction');  % Trigger error if function is not found
                end
            catch
                % If both .mat and function loading fail, provide an error message
                error(['Error: Could not find the data source for ', dataName, '. Please provide a valid .mat file or Matpower case function.']);
            end
        end
    end

    % Assign default values if arguments are not provided
    if nargin < 2, K = 20; end
    if nargin < 3, demand_ratio = 1.2; end
    if nargin < 4, line_cap_ratio = 1.0; end
    if nargin < 5, seed = 3; end

    % Set random seed for reproducibility
    rng(seed);

    % Display initial info
    disp('---------------------------------------------------');
    disp(['Data Name: ', dataName]);
    disp(['Number of Cascade Realizations (K): ', num2str(K)]);
    disp(['Random Number Generator Seed: ', num2str(seed)]);
    disp(['Power Demand Scaling Ratio: ', num2str(demand_ratio)]);
    disp(['Transmission Line Capacity Scaling Ratio: ', num2str(line_cap_ratio)]);
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


    % Initialize the waitbar before the loop
    h = waitbar(0, 'Progress: 0% done');
    
    % Loop through each realization (cascade event)
    for i = 1:K
        try
            % Update progress on the waitbar
            waitbar(i / K, h, sprintf('Progress: %.2f%% done', (i / K) * 100));
    
            % Retrieve the overloaded lines and their corresponding overload power demand
            [overload_line, oPd] = cs.computeOverload;
    
            % Store the overloaded lines and overload power demand values in the 'cases' cell array
            cases{i} = [[overload_line], [oPd]];
    
        catch
            warning('Error in realization %d. Skipping this iteration.', i);
            continue;  % Skip this iteration and continue with the next
        end
    end
    
    % Close the waitbar after the loop is completed
    close(h);
    

    % File name for result saving
    fileName = sprintf('%s_ol_profile_K%d_demandRatio%.2f_capRatio%.2f_seed%d', ...
    dataName, K, demand_ratio, line_cap_ratio, seed);


     % Save results
    try
        save(['results/', fileName, '.mat'], 'cases', '-v7.3');
        disp('Simulation complete. Results saved.');
    catch
        error('Error: Failed to save results. Check file permissions and paths.');
    end
end

