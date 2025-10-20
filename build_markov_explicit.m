function M = build_markov_explicit(W)

    % Flatten weights to column vector
    w = W(:);
    N = numel(w);

    % calculating M matrix withotu diagonals
    R = (1./w) * (w.');        % R is w^T / w
    A = min(1, R);             % elementwise acceptance
    A(1:N+1:end) = 0;          % zero out diagonal (no self-proposal)

    q = 1;                     % set to whatever
    M = q * A;                 % off-diagonals

    % Fill diagonal so each row sums to 1
    rowSums = sum(M, 2);
    M(1:N+1:end) = 1 - rowSums;

    % tidy up negative values
    M = max(M, power(10,-7));

end
