function K = gaussianKernel(sigma)
%GAUSSIANKERNEL Normalized 2-D Gaussian kernel G(x,y) for a given sigma.
%   Size is (2*ceil(3*sigma)+1)^2 so the kernel covers +-3 sigma, where
%   more than 99% of the Gaussian's weight lies.
    half = ceil(3 * sigma);
    [x, y] = meshgrid(-half:half, -half:half);
    K = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    K = K / sum(K(:));   % weights sum to 1 -> smoothing keeps mean brightness
end
