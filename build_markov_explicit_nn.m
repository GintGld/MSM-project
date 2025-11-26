function M = build_markov_explicit_nn(W)
% BUILD_MARKOV_NEAREST_NEIGHBOUR
%   Construct a Metropolis Markov matrix with proposals to nearest 
%   neighbours only (up to 4 neighbors with non-periodic boundaries).

    % Flatten weights to column vector
    w = W(:);
    N = numel(w);
    edge = size(W, 1);         % width of the (square) weight matrix

    % Initialize M matrix
    M = zeros(N, N);

    % Build the transition matrix for nearest neighbor Metropolis
    for from = 1:N
        % finding nearest neighbours for this state
        neigh = [from+1, from-1, from+edge, from-edge];

        % keep these within matrix boundaries
        neigh = neigh(neigh >= 1 & neigh <= N);
        col_from  = mod(from-1, edge) + 1;
        col_neigh = mod(neigh-1, edge) + 1;
        is_horiz  = abs(neigh - from) == 1;
        ok_horiz  = ~is_horiz | (abs(col_neigh - col_from) == 1);
        neigh     = neigh(ok_horiz);

        n_neigh = numel(neigh);
        
        % Proposal probability (uniform over neighbors)
        q = 1 / n_neigh;

        % Calculate acceptance probabilities and fill off-diagonals
        for idx = 1:n_neigh
            to = neigh(idx);
            % Metropolis acceptance probability
            alpha = min(1, w(to) / w(from));
            M(from, to) = q * alpha;
        end

        % Fill diagonal so row sums to 1
        M(from, from) = 1 - sum(M(from, :));
    end

    % clip negative values (shouldn't occur but safety check)
    M(M < 0) = 0;
    
    % renormalize rows to sum to 1
    rowSums = sum(M, 2);
    zeroRow = (rowSums == 0);
    rowSums(zeroRow) = 1;  % avoid division by zero

    M = M ./ rowSums;
    
end
