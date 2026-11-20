function [L, K] = logEdge(G, sigma)
%LOGEDGE Laplacian of Gaussian response, own implementation.
%   [L, K] = logEdge(G, sigma) convolves G directly with a LoG kernel built
%   from the closed form in lecture 18 (slide 63):
%       LoG(x,y) = (x^2 + y^2 - 2 sigma^2) / sigma^4 * exp(-(x^2 + y^2) / (2 sigma^2))
%   Smoothing with the Gaussian first suppresses the false edges that the
%   plain Laplace operator produces on noise. Like Laplace, the edges are
%   the zero-crossings of L.
%   K is returned so it can be shown/explained (Mexican hat shape).
    if nargin < 2
        sigma = 2;
    end
    half = ceil(3 * sigma);                 % +-3 sigma covers the whole hat
    [x, y] = meshgrid(-half:half, -half:half);
    r2 = x.^2 + y.^2;
    K = (r2 - 2 * sigma^2) / sigma^4 .* exp(-r2 / (2 * sigma^2));
    % Truncating the kernel leaves a small non-zero sum; force sum(K) = 0 so a
    % flat region gives exactly 0 response (no fake zero-crossings).
    K = K - mean(K(:));
    L = myConv2(G, K);
end
