function M = build_monte_carlo(W,nSteps)
%MC_TRANSITION_MATRIX  Empirically estimate transition matrix by simulation.
%
%   M = mc_transition_matrix(W, nSteps)
%
%   W       : vector or matrix of weights (target distribution)
%   nSteps  : number of Monte Carlo steps to simulate
%
%   M       : estimated NxN transition matrix from empirical frequencies
%
%   The chain uses Metropolis acceptance:
%       A(i→j) = min(1, w(j)/w(i))
%
%   Proposal: pick a random state uniformly among all other states.

    % --- flatten weight matrix ---
    w = W(:);
    N = numel(w);

    % --- storage for transition counts ---
    counts = zeros(N, N);

    % --- initialize at a random state ---
    current = randi(N);

    for step = 1:nSteps
        % propose random *different* state
        proposal = randi(N-1);
        if proposal >= current
            proposal = proposal + 1;
        end

        % Metropolis acceptance probability
        acceptProb = min(1, w(proposal) / w(current));

        % accept or reject
        if rand < acceptProb
            next = proposal;
        else
            next = current;
        end

        % record transition in count matrix
        counts(current, next) = counts(current, next) + 1;

        % move forward
        current = next;
    end

    % --- convert counts to transition probabilities ---
    M = zeros(N, N);
    for i = 1:N
        total = sum(counts(i, :));
        if total > 0
            M(i, :) = counts(i, :) / total;
        else
            % if no transitions recorded from state i
            M(i, i) = 1;
        end
    end
end