clear

%% User input and basic save mechanism

% Ask which dataset to use
use_teacher = '';
while ~ismember(upper(use_teacher), {'Y','N'})
    use_teacher = strtrim(input('Do you want to use the teacher''s weights? (Y/N): ', 's'));
    if ~ismember(upper(use_teacher), {'Y','N'})
        fprintf('Please answer Y or N.\n');
    end
end
use_teacher_flag = strcmpi(use_teacher, 'Y');

% If teacher was selected ask for edge size
edge = [];
if use_teacher_flag
    edge = NaN;
    while isnan(edge) || edge <= 0 || edge ~= floor(edge)
        edge_str = strtrim(input('What edge size do you want to use? (positive integer): ', 's'));
        edge = str2double(edge_str);

        if isnan(edge)
            fprintf('This is not a number. Please enter a positive integer.\n');
        elseif edge <= 0 || edge ~= floor(edge)
            fprintf('This is not a positive integer. Please try again.\n');
        end
    end
end

% Otherwise, ask for dataset dimensions
D = [];
if ~use_teacher_flag
    D = NaN;
    while isnan(D) || ~ismember(D, [1 2 3])
        D_str = strtrim(input('What dimension dataset do you want to use? (1, 2, or 3): ', 's'));
        D = str2double(D_str);

        if isnan(D) || ~ismember(D, [1 2 3])
            fprintf('Invalid choice. Please enter 1, 2, or 3.\n');
        end
    end
end

% ask which method to use, nn or any neighbour
nearest_neighbour_input = '';
while ~ismember(upper(nearest_neighbour_input), {'Y','N'})
    nearest_neighbour_input = strtrim(input('Do you want nearest neighbour (Y) or any neighbour (N): ', 's'));
    if ~ismember(upper(nearest_neighbour_input), {'Y','N'})
        fprintf('Please answer Y or N.\n');
    end
end
nearest_neighbour = strcmpi(nearest_neighbour_input, 'Y');

% ask how visual the output is
animate_input = '';
while ~ismember(upper(animate_input), {'Y','N'})
    animate_input = strtrim(input('Do you want animations at the cost of performance (Y/N)? ', 's'));
    if ~ismember(upper(animate_input), {'Y','N'})
        fprintf('Please answer Y or N.\n');
    end
end
doAnimate = strcmpi(animate_input, 'Y');

% Ask for number of iterations
max_iterations = NaN;
while isnan(max_iterations) || max_iterations <= 0 || max_iterations ~= floor(max_iterations)
    iter_str = strtrim(input('At what iteration do you want to stop at (int)? ', 's'));
    max_iterations = str2double(iter_str);
    
    if isnan(max_iterations)
        fprintf('This is not a number. Please enter a positive integer.\n');
    elseif max_iterations <= 0 || max_iterations ~= floor(max_iterations)
        fprintf('This is not a positive integer. Please try again.\n');
    end
end

% Save option
save_flag = [];
folder_name = '';
target_folder = '';

while isempty(save_flag)
    save_ans = strtrim(input( ...
        'Enter N to skip saving, or type a folder name to save data: ', 's'));

    if isempty(save_ans)
        fprintf('Please type N for no, or a folder name to save.\n');
        continue;
    end

    if strcmpi(save_ans, 'N')
        save_flag = false;
    else
        save_flag = true;
        folder_name = save_ans;
    end
end

% Folder creation logic when saving
if save_flag
    if isempty(folder_name)
        folder_name = 'run';
    end

    base_dir = 'output';
    if ~exist(base_dir, 'dir')
        mkdir(base_dir);
    end

    % If duplicate folder names add _1 _2 _3 etc.
    target_folder = fullfile(base_dir, folder_name);
    if exist(target_folder, 'dir')
        idx = 1;
        while exist(fullfile(base_dir, sprintf('%s_%d', folder_name, idx)), 'dir')
            idx = idx + 1;
        end
        folder_name = sprintf('%s_%d', folder_name, idx);
        target_folder = fullfile(base_dir, folder_name);
    end

    mkdir(target_folder);
    fprintf('Data will be saved in folder: %s\n', target_folder);
else
    fprintf('Data will not be saved.\n');
end


%% seting up the data for computation

if use_teacher_flag
    % load teachers weights
    [~, W] = MetroW(edge);
else
    % load the relevant perlin noise data
    switch D
        case 1
            S = load('perlin_noise1d.mat');
        case 2
            S = load('perlin_noise2d.mat');
        case 3
            S = load('perlin_noise3d.mat');
    end

    % load the first variable in the mat file, and check correctly exported
    fn = fieldnames(S);
    if isempty(fn)
        error('Loaded MAT file does not contain any variables.');
    end
    W = S.(fn{1});
end

% Plot 2D Perlin noise if animate + not teacher + 2D
if doAnimate && ~use_teacher_flag && D == 2
    figure('Name', 'Perlin Noise Distribution', 'NumberTitle', 'off');
    imagesc(W);
    axis image;
    colorbar;
    xlabel('x');
    ylabel('y');
    title('2D Perlin Noise Weight Distribution');
end


%% Calculation part

% create the "brute force" Markov matrix
if nearest_neighbour
    M_explicit = build_markov_explicit_nn(W);
else
    M_explicit = build_markov_explicit(W);
end

% Run Monte Carlo estimate and get chi^2 history
if nearest_neighbour
    [M, chi_history] = build_monte_carlo_nearest(W, max_iterations, M_explicit, doAnimate);
else
    [M, chi_history] = build_monte_carlo(W, max_iterations, M_explicit, doAnimate);
end

% Plot chi vector vs step (step 0 .. nSteps)
figure;
% Use +1 offset on x (since log(0) is undefined) and avoid zeros in y
x = (0:numel(chi_history)-1) + 1;
y = chi_history + eps; % preventing the unlikely log(0) case
 
loglog(x, y, '-o');

% Show original step numbers on x-axis (subtract the +1 offset for labels)
xt = get(gca, 'XTick');
set(gca, 'XTickLabel', arrayfun(@(v) num2str(v-1), xt, 'UniformOutput', false));
xlabel('Step');
ylabel('\chi^2');
title('\chi^2 convergence of Monte Carlo transition matrix');
grid on;

% If animation was enabled, plot comparison of matrices
if doAnimate
    figure('Name', 'Markov Matrix Comparison', 'NumberTitle', 'off');
    tlo = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    
    % left plot explicit calculation of matrix
    axExplicit = nexttile(tlo, 1);
    imagesc(axExplicit, log10(M_explicit + eps));  % necessary log scale, eps prevents log(0)
    axis(axExplicit, 'image');
    colorbar(axExplicit);
    xlabel(axExplicit, 'To state');
    ylabel(axExplicit, 'From state');
    title(axExplicit, 'log_{10}(M_{explicit}) (Calculated)');
    
    % right plot Monte Carlo estimate of matrix
    axMC = nexttile(tlo, 2);
    imagesc(axMC, log10(M + eps));  % same log scale
    axis(axMC, 'image');
    colorbar(axMC);
    xlabel(axMC, 'To state');
    ylabel(axMC, 'From state');
    title(axMC, 'log_{10}(M) (Monte Carlo Estimate)');
    
    % match the color limit of the plots for easier comparison
    clim_explicit = clim(axExplicit);
    clim_mc = clim(axMC);
    common_clim = [min(clim_explicit(1), clim_mc(1)), max(clim_explicit(2), clim_mc(2))];
    clim(axExplicit, common_clim);
    clim(axMC, common_clim);
end

%% Saving as many parameters as possible

if save_flag
    % Save Markov matrix
    save(fullfile(target_folder, 'M_explicit.mat'), 'M_explicit');
    save(fullfile(target_folder, 'M.mat'), 'M');

    % Save algorithm parameters
    save(fullfile(target_folder, 'parameters.mat'), 'nearest_neighbour');
    
    % Save convergence parameters
    save(fullfile(target_folder, 'convergence_params.mat'), 'max_iterations');

    % Save W
    save(fullfile(target_folder, 'W.mat'), 'W');

    % Save the chi2 squared values
    save(fullfile(target_folder, 'chi_history.mat'), 'chi_history');

    fprintf('Data saved in: %s\n', target_folder);
end
