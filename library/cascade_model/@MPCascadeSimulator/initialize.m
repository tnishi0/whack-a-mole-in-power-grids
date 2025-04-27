function initialize(obj)
    % Initialize the system in preparation for a cascade event simulation.
    
    % Reset the system state to the initial conditions.
    obj.rmpc = obj.rmpc0;
    
    % Reset the time step to zero, marking the start of the simulation.
    obj.t = 0;
    
    % Initialize and allocate memory for state variables:
    % nl: number of transmission lines (branches).
    % Outlines: Status of each transmission line (1 = in service, 0 = out of service).
    % T: Transmission line temperatures (initialized to zero).
    % Proc: Sequence of failures for each line (sparse array).
    % Proc_time: Time steps at which failures occur (sparse array).
    % SecFail: Secondary failures (sparse array).
    nl = obj.nl;  % The number of transmission lines (branches).
    
    % Initialize all lines as in-service (1).
    obj.Outlines = ones(1, nl);
    
    % Set out-of-service lines (from rmpc0 data) to 0.
    obj.Outlines(obj.rmpc0.branch(:, 11) == 0) = 0;
    
    % Initialize transmission line temperatures to zero.
    obj.T = zeros(nl, 1);
    
    % Initialize sparse arrays for failure tracking:
    obj.Proc = spalloc(1, nl, floor(0.1 * nl));  % Sparse array for primary failures.
    obj.Proc_time = spalloc(1, nl, floor(0.1 * nl));  % Sparse array for failure times.
    obj.SecFail = spalloc(1, nl, floor(0.2 * nl));  % Sparse array for secondary failures.
    
    % Set the simulator status to "Initialized", marking the readiness for the cascade event.
    obj.Status = MPCasSimStatus.Initialized;  % Simulator is initialized.

end