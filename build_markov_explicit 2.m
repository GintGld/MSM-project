<<<<<<< HEAD
function M = build_markov_explicit(W)

    % Flatten weights to column vector
    w = W(:);
    N = numel(w);

    % calculating M matrix withotu diagonals
    R = (1./w) * (w.');        % R is w^T / w
    A = min(1, R);             % elementwise acceptance
    A(1:N+1:end) = 0;          % zero out diagonal (no self-proposal)

    q = 1 / N;                 % set to whatever
    M = q * A;                 % off-diagonals

    % Fill diagonal so each row sums to 1
    rowSums = sum(M, 2);
    M(1:N+1:end) = 1 - rowSums;

    % tidy up negative values
    M = max(M, power(10,-7));

end
=======
function M = build_markov_explicit(W)

    % Flatten weights to column vector
    w = W(:);
    N = numel(w);

    % calculating M matrix without diagonals
    R = (1./w) * (w.');        % R is w^T / w
    A = min(1, R);             % elementwise acceptance
    A(1:N+1:end) = 0;          % zero out diagonal (no self-proposal)

    % Proposal probability
    %q = 1;                     % set to whatever
    %M = q * A;                 % off-diagonals

    % Fill diagonal so each row sums to 1
    %rowSums = sum(M, 2);
    %M(1:N+1:end) = 1 - rowSums;

    % tidy up negative values
    %M = max(M, power(10,-7));
    
    % Proposal probability: uniform among other states
    q = 1 / (N-1);

    % Off-diagonals: proposal * acceptance
    M = q * A;

    % Diagonal: whatever is left so rows sum to 1
    rowSums = sum(M, 2);
    M(1:N+1:end) = 1 - rowSums;

    % If tiny numerical negatives appear, clip small negatives and renormalize rows
    tol = -1e-12;
    M(M < tol) = 0;                 % remove significant negatives if any
    % renormalize rows to sum to 1 (robust)
    rowSums = sum(M,2);
    zeroRow = rowSums == 0;
    if any(zeroRow)
        % If a row has zero total (shouldn't happen), put probability 1 on diagonal
        M(zeroRow, :) = 0;
        M(zeroRow + (0:sum(zeroRow)-1)*N) = 1; % set diagonals for those rows
        rowSums = sum(M,2);
    end
    M = M ./ rowSums;  % normalize each row to 1
end
>>>>>>> 21d51b8326b3d83b2390be5ac22adca75175612b
