function trigger(obj, triggers)
    % Choose triggers and set them out-of-service.
    % This function selects which transmission lines will initially 
    % fail in the cascade.
    %
    % The selection is done based on the triggering strategy specified by 
    % the obj.TriggeringStrategy function handle.
    
    % Check if the system is initialized before proceeding.
    if obj.Status ~= MPCasSimStatus.Initialized
        error('System must be initialized before triggering a cascade event.');
    end
    
    % If no triggers are provided, use the default triggering strategy.
    if nargin < 2 || isempty(triggers)
       triggers = obj.TriggeringStrategy(obj.ntrig);  % Choose triggers randomly based on strategy
    end
    
    % Validate triggers: ensure that we have a valid list of lines to trigger
    if isempty(triggers) || any(triggers <= 0) || any(triggers > obj.nl)
        error('Invalid triggers specified. Ensure that the trigger indices are valid.');
    end
    
    % Set the selected triggers out-of-service.
    cutoff_line(obj, triggers);  % Function to disconnect the specified lines
    
    % Update the status to indicate the system is now in the cascading state.
    obj.Status = MPCasSimStatus.Cascading;
    
    % Record the triggered lines as part of the cascade event process.
    obj.Proc(1 : obj.ntrig) = triggers;

end