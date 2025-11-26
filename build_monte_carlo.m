function [M, chi_history] = build_monte_carlo(W, nSteps, M_explicit, doAnimate)

    w = W(:);
    N = numel(w);

    if ~isequal(size(M_explicit), [N N])
        error('M_explicit must be %d x %d', N, N);
    end

    counts    = zeros(N, N);
    rowTotals = zeros(N, 1);
    
    % Track state visit counts (for animation)
    stateCounts = zeros(N, 1);

    mask = M_explicit > 0;              % avoid division by zero

    % step 0: M = 0 everywhere
    chi_total        = sum(M_explicit(mask));
    chi_history      = zeros(nSteps+1, 1);
    chi_history(1)   = chi_total;

    current = randi(N);

    % Animation
    if doAnimate
        fig = figure('Name', 'Monte Carlo Markov matrix', ...
                     'NumberTitle', 'off');

        tlo = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

        % LEFT: state visit counts (reshaped to match W)
        edge = size(W, 1);
        axCounts = nexttile(tlo, 1);
        stateCountsMatrix = reshape(stateCounts, edge, edge);
        imCounts = imagesc(axCounts, stateCountsMatrix);
        axis(axCounts, 'image');
        colorbar(axCounts);
        xlabel(axCounts, 'x');
        ylabel(axCounts, 'y');
        title(axCounts, sprintf('State Visit Counts (Step %d)', 0));

        % RIGHT: chi^2 vs step (linear scale with auto y-axis)
        axChi = nexttile(tlo, 2);
        chiLine = plot(axChi, 0, chi_history(1), '-');
        xlabel(axChi, 'Step');
        ylabel(axChi, '\chi^2');
        title(axChi, '\chi^2 convergence');
        xlim(axChi, [0, nSteps]);
        ylim(axChi, 'auto');

        drawnow;
        lastUpdate = tic;  % for "every ~1 second" logic
    else
        h = waitbar(0, 'Running Monte Carlo...');
    end

    for step = 1:nSteps

        from = current;

        % propose new state different from current
        proposal = randi(N-1);
        if proposal >= from
            proposal = proposal + 1;
        end

        % Metropolis acceptance
        if rand < min(1, w(proposal)/w(from))
            next = proposal;
        else
            next = from;
        end

        % ----- old row contribution (before updating counts) -----
        if rowTotals(from) > 0
            M_row_old = counts(from,:) / rowTotals(from);
        else
            M_row_old = zeros(1, N);    % before any visits, row is all zeros
        end

        row_mask     = mask(from,:);
        explicit_row = M_explicit(from,:);

        diff_old     = M_row_old(row_mask) - explicit_row(row_mask);
        chi_row_old  = sum((diff_old.^2) ./ explicit_row(row_mask));

        % ----- update counts and totals for this row -----
        counts(from, next) = counts(from, next) + 1;
        rowTotals(from)    = rowTotals(from) + 1;
        
        % Track state visits
        stateCounts(next) = stateCounts(next) + 1;

        % ----- new row contribution (after updating counts) -----
        M_row_new   = counts(from,:) / rowTotals(from);
        diff_new    = M_row_new(row_mask) - explicit_row(row_mask);
        chi_row_new = sum((diff_new.^2) ./ explicit_row(row_mask));

        % ----- update global chi^2 -----
        chi_total            = chi_total - chi_row_old + chi_row_new;
        chi_history(step+1)  = chi_total;

        current = next;

        if doAnimate
            % Update every ~1 second OR at least every 100 iterations
            if toc(lastUpdate) > 1 || mod(step, 100) == 0
                % left: state visit counts reshaped
                stateCountsMatrix = reshape(stateCounts, edge, edge);
                set(imCounts, 'CData', stateCountsMatrix);
                title(axCounts, sprintf('State Visit Counts (Step %d)', step));

                % right: chi^2 curve
                set(chiLine, 'XData', 0:step, ...
                             'YData', chi_history(1:step+1));

                drawnow limitrate;
                lastUpdate = tic;
            end
        else
            if mod(step, max(1000, floor(nSteps/100))) == 0
                waitbar(step/nSteps, h);
            end
        end
    end

    % build final empirical M
    M = zeros(N, N);
    for i = 1:N
        if rowTotals(i) > 0
            M(i,:) = counts(i,:) / rowTotals(i);
        else
            M(i,i) = 1;   % fallback for never-visited rows
        end
    end

    if ~doAnimate
        waitbar(1, h);
        pause(0.05);
        close(h);
    end
end
