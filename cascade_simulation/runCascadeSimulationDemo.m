% Demo script to run one of the cascade simulation strategies

% Add necessary directories to the MATLAB path
addpath('frequency-based');
addpath('failure-based');
addpath('overload-based');
addpath('../library/cascade_model/');
addpath('../library/matpower6.0/');

% Choose the strategy you want to run
strategyChoice = input('Choose a strategy (1: Failure-based, 2: Frequency-based, 3: Overload-based): ');

% Set the parameters for the chosen strategy
dataName = 'case3375wp';  % or your own case file name or function
K = 100;  % Number of cascade realizations
demand_ratio = 1.2;
line_cap_ratio = 1.0;
seed = 1;

if strategyChoice == 1  % Failure-based strategy
    ffl = input('Enter ffl (0: Upgrade all failing lines, 1: Upgrade first failing lines): ');
    toInf = input('Enter toInf (0: Upgrade to overloaded value, 1: Set to infinity): ');
    runMPCS_failure(dataName, K, demand_ratio, line_cap_ratio, seed, ffl, toInf);

elseif strategyChoice == 2  % Frequency-based strategy
    NofInc = input('Enter the number of planned upgrade iterations (NofInc): ');
    threshold = input('Enter the vulnerable line failure threshold: ');
    ffl = input('Enter ffl (0: Upgrade all failing lines, 1: Upgrade first failing lines): ');
    toInf = input('Enter toInf (0: Upgrade to overloaded value, 1: Set to infinity): ');
    runMPCS_frequency(dataName, NofInc, K, demand_ratio, line_cap_ratio, threshold, seed, ffl, toInf);

elseif strategyChoice == 3  % Overload-based strategy
    runMPCS_overload(dataName, K, demand_ratio, line_cap_ratio, seed);
    
else
    disp('Invalid strategy choice. Please choose 1, 2, or 3.');
end