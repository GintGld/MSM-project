function M = build_markov_explicit(W)

    % Flatten weights to column vector
    w = W(:);
    N = numel(w);

    % calculating M matrix without diagonals
    R = (1./w) * (w.');        % R is w^T / w
    A = min(1, R);             % elementwise acceptance
    A(1:N+1:end) = 0;          % zero out diagonal (no self-proposal)

    q = 1 / (N-1);             % normalised
    M = q * A;                 % off-diagonals

    % Fill diagonal so each row sums to 1
    rowSums = sum(M, 2);
    M(1:N+1:end) = 1 - rowSums;

    % clip negative values
    M(M < 0) = 0;
    
    % renormalize rows to sum to 1
    rowSums = sum(M,2);
    zeroRow = (rowSums == 0);
    rowSums(zeroRow) = 1;  % avoid division by zero

    M = M ./ rowSums;  % normalize each row to 1 (This line needs modification to meet teachers expectations)
    
end
