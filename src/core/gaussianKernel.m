function K = gaussianKernel(sigma)
%GAUSSIANKERNEL Kernel Gaussian 2-D ternormalisasi untuk sigma tertentu.
%   Ukurannya (2*ceil(3*sigma)+1)^2 supaya kernel mencakup +-3 sigma, daerah
%   tempat lebih dari 99% bobot Gaussian berada.
    half = ceil(3 * sigma);
    [x, y] = meshgrid(-half:half, -half:half);
    K = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    K = K / sum(K(:));   % bobot berjumlah 1 -> brightness rata-rata tetap
end
