function out = myConv2(I, K)
%MYCONV2 2-D convolution written from scratch ('same' size, replicate border).
%   out = myConv2(I, K) convolves the gray image I (any numeric type) with
%   kernel K and returns a double matrix the same size as I. Replaces the
%   built-in conv2 used in the lecture so every edge operator is our own.
%
%   Instead of looping over every pixel (slow in MATLAB) we loop over the
%   kernel elements: each term K(i,j) * shifted(I) is a whole-matrix
%   operation, so a 3x3 kernel costs only 9 matrix multiply-adds.
    I = double(I);
    K = double(K);
    [H, W] = size(I);
    [kr, kc] = size(K);

    % Convolution = correlation with the kernel rotated 180 degrees
    Kf = rot90(K, 2);

    % Padding before/after so the kernel "center" lands on each pixel.
    % For even sizes (Roberts 2x2) the extra row/col goes after.
    padTop  = floor((kr - 1) / 2);  padBottom = kr - 1 - padTop;
    padLeft = floor((kc - 1) / 2);  padRight  = kc - 1 - padLeft;

    % Replicate padding through clamped indices (no padarray needed)
    rowIdx = [ones(1, padTop),  1:H, H * ones(1, padBottom)];
    colIdx = [ones(1, padLeft), 1:W, W * ones(1, padRight)];
    P = I(rowIdx, colIdx);

    out = zeros(H, W);
    for i = 1:kr
        for j = 1:kc
            w = Kf(i, j);
            if w ~= 0   % zero coefficients contribute nothing, skip them
                out = out + w * P(i:i + H - 1, j:j + W - 1);
            end
        end
    end
end
