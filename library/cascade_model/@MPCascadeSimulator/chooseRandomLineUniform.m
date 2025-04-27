function line_idx = chooseRandomLineUniform(obj, n)
    % Get a set of random lines uniformly.
    %
    % Returns a set of n lines chosen randomly and uniformly from all
    % in-service lines in the network.
    %
    % Inputs:
    %   n : number of random lines to select
    %
    % Outputs:
    %   line_idx : indices of the randomly selected in-service lines
    
    % Column indices for Matpower case data
    BR_STATUS = 11;
    
    % Get indices of in-service lines
    inService = find(obj.rmpc.branch(:, BR_STATUS));
    
    % Check if requested number of lines exceeds available in-service lines
    if n > length(inService)
        error('Requested more lines than available in-service lines.');
    end
    
    % Randomly permute the in-service lines and select the first n
    ix = randperm(length(inService));
    line_idx = inService(ix(1:n))';