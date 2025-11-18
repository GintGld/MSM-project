clear

%% =========================
%  1) USER INPUT + SAVE SETUP
%  =========================

% --- Teacher weights or Perlin data? ---
use_teacher = '';
while ~ismember(upper(use_teacher), {'Y','N'})
    use_teacher = strtrim(input('Do you want to use the teacher''s weights? (Y/N): ', 's'));
    if ~ismember(upper(use_teacher), {'Y','N'})
        fprintf('Please answer Y or N.\n');
    end
end
use_teacher_flag = strcmpi(use_teacher, 'Y');

% --- If teacher: ask for edge size ---
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

% --- If Perlin: ask for dimension D = 1,2,3 ---
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

% --- Save option: N = no, anything else = folder name ---
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

% --- If saving, create unique folder under output/ now ---
if save_flag
    if isempty(folder_name)
        folder_name = 'run';
    end

    base_dir = 'output';
    if ~exist(base_dir, 'dir')
        mkdir(base_dir);
    end

    % Ensure unique folder name: folder, folder_1, folder_2, ...
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


%% =================
%  2) LOADING DATA
%  =================

if use_teacher_flag
    % Teacher weights: generate with MetroW
    [~, W] = MetroW(edge);
else
    % Perlin data: load from file based on D
    switch D
        case 1
            S = load('perlin_noise1d.mat');
        case 2
            S = load('perlin_noise2d.mat');
        case 3
            S = load('perlin_noise3d.mat');
    end

    % Extract first variable from MAT file as data_file
    fn = fieldnames(S);
    if isempty(fn)
        error('Loaded MAT file does not contain any variables.');
    end
    data_file = S.(fn{1});
end


%% ==========================
%  3) CALCULATE MARKOV MATRIX
%  ==========================

if use_teacher_flag
    M = build_markov_explicit(W);
else
    M = build_markov_explicit(data_file);
end


%% =================
%  4) SAVING DATA
%  =================

if save_flag
    % Save Markov matrix
    save(fullfile(target_folder, 'M.mat'), 'M');

    % Optionally save W / data_file depending on branch
    if use_teacher_flag && exist('W', 'var')
        save(fullfile(target_folder, 'W.mat'), 'W');
    end
    if ~use_teacher_flag && exist('data_file', 'var')
        save(fullfile(target_folder, 'data_file.mat'), 'data_file');
    end

    fprintf('Data saved in: %s\n', target_folder);
end



    

%load('perlin_noise2d.mat') % Named data_file

%[~, W] = MetroW(edge);

%M = build_markov_explicit(data_file);

imagesc(log10(M));
colorbar;
