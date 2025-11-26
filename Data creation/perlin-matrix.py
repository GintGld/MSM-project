from scipy.io import savemat
import numpy as np
from noise import pnoise1, pnoise2, pnoise3
import matplotlib.pyplot as plt

def perlin(dimension: int, size: int, *,
           scale: float = 50.0,
           octaves: int = 1,
           persistence: float = 0.5,
           lacunarity: float = 2.0,
           seed: int | None = None,
           normalize: bool = False) -> np.ndarray:
    """
    Returns array of shape size^dimension of Perlin noise

    scale: larger -> smoother features
    octaves: number of levels of detail
    persistence: amplitude of each octave
    lacunarity: frequency of each octave
    normalize: if True, map from [-1,1] to [0,1]
    """
    if dimension not in (1, 2, 3):
        raise ValueError("Only 1D, 2D, or 3D supported with built-ins in 'noise'.")

    base = 0 if seed is None else int(seed)

    if dimension == 1:
        out = np.empty((size,), dtype=np.float16)
        for i in range(size):
            x = i / scale
            out[i] = pnoise1(x, octaves=octaves, persistence=persistence,
                             lacunarity=lacunarity, repeat=1024, base=base)
        return (out + 1)/2 if normalize else out

    if dimension == 2:
        out = np.empty((size, size), dtype=np.float16)
        for i in range(size):
            x = i / scale
            for j in range(size):
                y = j / scale
                out[i, j] = pnoise2(x, y, octaves=octaves, persistence=persistence,
                                    lacunarity=lacunarity, repeatx=1024, repeaty=1024, base=base)
        return (out + 1)/2 if normalize else out

    # dimension == 3
    out = np.empty((size, size, size), dtype=np.float16)
    for i in range(size):
        x = i / scale
        for j in range(size):
            y = j / scale
            for k in range(size):
                z = k / scale
                out[i, j, k] = pnoise3(x, y, z, octaves=octaves, persistence=persistence,
                                       lacunarity=lacunarity,
                                       repeatx=1024, repeaty=1024, repeatz=1024, base=base)
    return (out + 1)/2 if normalize else out

def save_matlab(filename: str, variable_name: str, data: np.ndarray) -> None:
    savemat(filename, {variable_name: data})

def plot_2d(matrix: np.ndarray) -> None:
    plt.imshow(matrix, cmap='gray')
    plt.colorbar()
    plt.show()

def plot_1d(array: np.ndarray) -> None:
    x = np.arange(len(array))
    plt.figure()
    plt.bar(x, array, width=1.0, edgecolor='black')
    plt.show()

if __name__ == "__main__":
    size = 50
    dimension = 3
    noise_matrix = perlin(dimension, size, scale=30.0, octaves=3,
                          persistence=0.5, lacunarity=2.0, seed=40, normalize=True)

    #plot_1d(noise_matrix)
    save_matlab("perlin_noise3d.mat", "data_file", noise_matrix)