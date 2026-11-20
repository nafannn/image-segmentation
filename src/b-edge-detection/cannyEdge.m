function [E, M] = cannyEdge(G, low, high, sigma)
%CANNYEDGE Canny edge detector via MATLAB's built-in EDGE (allowed by the spec).
%   [E, M] = cannyEdge(G, low, high, sigma)
%     G         : double gray image in [0, 255]
%     low, high : hysteresis thresholds T1 < T2, as fractions (0..1)
%     sigma     : std dev of the Gaussian smoothing
%   E : binary edge map (1-pixel thin, after non-maximum suppression and
%       hysteresis: strong edges > T2 plus weak edges > T1 connected to them)
%   M : smoothed Sobel gradient magnitude, only for display ("response")
    if low >= high
        error('cannyEdge:thresholds', ...
            'Low threshold (T1 = %.3g) harus lebih kecil dari high threshold (T2 = %.3g).', low, high);
    end
    E = edge(G / 255, 'canny', [low high], sigma);

    % Display-only response with our own operators: Gaussian then Sobel
    Gs = myConv2(G, gaussianKernel(sigma));
    M = sobelEdge(Gs);
end
