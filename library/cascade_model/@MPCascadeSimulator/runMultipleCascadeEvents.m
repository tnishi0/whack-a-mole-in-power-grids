function runMultipleCascadeEvents(obj, K, dispon)
% Run K cascade simulations.

% If 'dispon' (display option) is not provided, set it to 1 (enabled)
if nargin < 3, dispon = 1; end

% If 'K' (number of realizations) is not provided, set it to 20 (default value)
if nargin < 2, K = 20;  end

% Ensure that K is an integer value
if ~isscalar(K) || mod(K, 1) ~= 0
    error('K must be an integer.')  
end

% Pre-allocate memory for the failure history and CPU times.
obj.HistoryFailureSeq = spalloc(K, obj.nl, floor(0.1 * K * obj.nl));
obj.CPUTime = nan(K, 1);

% Run K simulations in sequence.
for i = 1:K
    runCascadeEvent(obj)
    if dispon
        fprintf('Simulation %d/%d complete.\n', i, K);
        fprintf('Primary Failures: %d\n', sum(obj.Proc > 0) - obj.ntrig);
    end
end
