function [L, K] = logEdge(G, sigma)
%LOGEDGE Respons Laplacian of Gaussian, implementasi sendiri.
%   [L, K] = logEdge(G, sigma) mengkonvolusi G langsung dengan kernel LoG
%   yang dibangun dari rumus tertutup:
%       LoG(x,y) = (x^2 + y^2 - 2 sigma^2) / sigma^4
%                  * exp(-(x^2 + y^2) / (2 sigma^2))
%   Smoothing Gaussian lebih dulu menekan edge palsu yang muncul kalau
%   operator Laplace dipakai langsung pada citra ber-noise. Sama seperti
%   Laplace, edge-nya adalah zero-crossing dari L.
%   K ikut dikembalikan supaya bisa ditampilkan dan dijelaskan bentuknya
%   (Mexican hat).
    if nargin < 2
        sigma = 2;
    end
    half = ceil(3 * sigma);                 % +-3 sigma menutup seluruh topi
    [x, y] = meshgrid(-half:half, -half:half);
    r2 = x.^2 + y.^2;
    K = (r2 - 2 * sigma^2) / sigma^4 .* exp(-r2 / (2 * sigma^2));
    % Kernel yang dipotong menyisakan jumlah kecil yang tidak nol; paksa
    % sum(K) = 0 supaya region datar memberi respons tepat 0 (tidak muncul
    % zero-crossing palsu).
    K = K - mean(K(:));
    L = myConv2(G, K);
end
