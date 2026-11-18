function rgb = labelToRgb(L, cmap)
%LABELTORGB Convert an integer label image to an RGB image.
%   L    : label image, 0 = unlabeled (drawn black), 1..K = region/class.
%   cmap : K-by-3 colors in [0,1]. If omitted, a random but repeatable
%          palette is generated (useful for split-and-merge regions).
    L = double(L);
    L(isnan(L)) = 0;
    K = max(L(:));
    if nargin < 2 || isempty(cmap)
        rs = RandStream('mt19937ar', 'Seed', 4073);   % fixed seed -> same colors every run
        cmap = 0.15 + 0.85 * rand(rs, max(K, 1), 3);
    end
    lut = [0 0 0; cmap];                % row 1 is for label 0
    idx = L + 1;                        % shift labels so 0 -> row 1
    rgb = zeros([size(L) 3]);
    for c = 1:3
        channel = lut(:, c);
        rgb(:, :, c) = channel(idx);    % look-up per pixel
    end
end
