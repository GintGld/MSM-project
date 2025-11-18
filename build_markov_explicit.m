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

    % If tiny numerical negatives appear, clip small negatives and renormalize rows
    tol = -1e-12;
    M(M < tol) = 0;                 % remove significant negatives if any
    % renormalize rows to sum to 1 (robust)
    rowSums = sum(M,2);
    zeroRow = (rowSums == 0);
    rowSums(zeroRow) = 1;  % avoid division by zero

%    if any(zeroRow)
%        % If a row has zero total (shouldn't happen), put probability 1 on diagonal
%        M(zeroRow, :) = 0;
%        M(zeroRow + (0:sum(zeroRow)-1)*N) = 1; % set diagonals for those rows
%        rowSums = sum(M,2);
%    end
    M = M ./ rowSums;  % normalize each row to 1
end
