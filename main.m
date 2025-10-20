load('perlin_noise2d.mat')

M = build_markov_explicit(data_file);

imagesc(M);
colorbar;