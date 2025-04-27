function [ci, sizes] = components(obj, A)
    % Components function for finding connected components in a graph
    % represented by an adjacency matrix A. This works for both directed 
    % and undirected graphs.
    
    % Convert to sparse if needed
    if ~issparse(A)
        A = sparse(A);  % Convert to sparse if it's not already sparse
    end
    
    % Automatically check if the matrix is asymmetric and transpose if needed
    if ~issymmetric(A)
        A = A';  % Transpose if the matrix is asymmetric
    end

    % Rest of the function logic follows (DFS, component finding, etc.)
    n = size(A, 1);  % Number of nodes
    ci = zeros(n, 1);  % Component indices
    visited = false(n, 1);  % Visited nodes
    component = 0;  % Component counter

    % Depth-First Search (DFS) for each unvisited node
    for i = 1:n
        if ~visited(i)
            component = component + 1;
            stack = i;
            while ~isempty(stack)
                node = stack(end);
                stack(end) = [];  % Pop the last element
                if ~visited(node)
                    visited(node) = true;
                    ci(node) = component;
                    neighbors = find(A(node, :) ~= 0);  % Get neighbors
                    stack = [stack; neighbors(:)];  % Push neighbors onto the stack
                end
            end
        end
    end

    % Calculate the size of each connected component
    sizes = accumarray(ci, 1);
end