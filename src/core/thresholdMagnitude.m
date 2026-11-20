function [E, T] = thresholdMagnitude(M, mode, value, candidates)
%THRESHOLDMAGNITUDE Turn an edge strength map into a binary edge map.
%   [E, T] = thresholdMagnitude(M, mode, value, candidates)
%     M          : edge strength (gradient magnitude or zero-crossing slope), >= 0
%     mode       : 'otsu'       - T chosen automatically (Otsu, 256-bin histogram)
%                  'percentile' - T = value-th percentile of the strengths (0..100)
%                  'manual'     - T = value * max(M)  (value in 0..1)
%     candidates : optional logical mask of pixels that may become edges
%                  (used for zero-crossings: only pixels where the sign changes)
%   E : logical edge map (M > T, restricted to candidates)
%   T : threshold actually used, in the units of M
    if nargin < 4 || isempty(candidates)
        candidates = true(size(M));
    end
    v = M(candidates);                 % strengths that take part in the statistics
    if isempty(v) || max(v) <= 0
        E = false(size(M));
        T = 0;
        return;
    end

    switch lower(mode)
        case 'otsu'
            T = otsuThreshold(v);
        case 'percentile'
            s = sort(v(:));
            p = min(max(value, 0), 100);
            idx = max(1, ceil(p / 100 * numel(s)));   % rank of the p-th percentile
            T = s(idx);
        case 'manual'
            T = min(max(value, 0), 1) * max(v);
        otherwise
            error('thresholdMagnitude:mode', 'Unknown threshold mode "%s".', mode);
    end
    E = candidates & (M > T);
end

function T = otsuThreshold(v)
%OTSUTHRESHOLD Otsu's method written from scratch: pick the level that
%   maximizes the between-class variance sigma_B^2(k) of the histogram.
    vmax = max(v);
    bins = 256;
    % Map strengths to bins 1..256 and build the normalized histogram p(i)
    b = min(bins, floor(v / vmax * (bins - 1)) + 1);
    counts = accumarray(b(:), 1, [bins 1]);
    p = counts / sum(counts);

    levels = (0:bins - 1)';
    omega = cumsum(p);                 % class-0 probability  w0(k)
    mu = cumsum(p .* levels);          % class-0 cumulative mean  mu(k)
    muT = mu(end);                     % global mean
    % sigma_B^2(k) = (muT*w0 - mu)^2 / (w0 * (1 - w0))
    denom = omega .* (1 - omega);
    sigmaB = zeros(bins, 1);
    ok = denom > 0;
    sigmaB(ok) = (muT * omega(ok) - mu(ok)).^2 ./ denom(ok);

    [~, kStar] = max(sigmaB);          % best split: bins 1..kStar are background
    T = (kStar - 1 + 0.5) / (bins - 1) * vmax;   % back to strength units (bin edge)
end
