load('perlin_noise2d.mat')

M_theory = build_markov_explicit(data_file);

imagesc(M_theory);
colorbar;
