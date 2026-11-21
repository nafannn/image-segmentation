function [E, T] = thresholdMagnitude(M, mode, value, candidates)
%THRESHOLDMAGNITUDE Ubah peta kekuatan tepi jadi peta tepi biner.
%   [E, T] = thresholdMagnitude(M, mode, value, candidates)
%     M          : kekuatan tepi (magnitude gradien / slope), >= 0
%     mode       : 'otsu'       - T dipilih otomatis (Otsu, histogram 256 bin)
%                  'percentile' - T = percentile ke-value dari nilai (0..100)
%                  'manual'     - T = value * max(M)  (value di 0..1)
%     candidates : mask logical opsional berisi piksel yang boleh jadi tepi
%                  (untuk zero-crossing: hanya piksel yang tandanya berubah)
%   E : peta tepi logical (M >= T, dibatasi ke candidates)
%   T : threshold yang benar-benar dipakai, dalam satuan M
%
%   Piksel dianggap edge kalau kekuatannya mencapai T (>=). Memakai > akan
%   membuang piksel yang nilainya tepat sama dengan T, dan itu bisa segerombol
%   kalau T jatuh di puncak histogram yang datar.
    if nargin < 4 || isempty(candidates)
        candidates = true(size(M));
    end
    v = M(candidates);                 % kekuatan yang ikut dihitung statistiknya
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
    E = candidates & (M >= T);
end

function T = otsuThreshold(v)
%OTSUTHRESHOLD Metode Otsu yang ditulis dari nol: pilih level yang
%   memaksimalkan between-class variance sigma_B^2(k) pada histogram.
    vmax = max(v);
    bins = 256;
    % Petakan kekuatan ke bin 1..256 lalu susun histogram ternormalisasi p(i)
    b = min(bins, floor(v / vmax * (bins - 1)) + 1);
    counts = accumarray(b(:), 1, [bins 1]);
    p = counts / sum(counts);

    levels = (0:bins - 1)';
    omega = cumsum(p);                 % peluang kelas-0  w0(k)
    mu = cumsum(p .* levels);          % rerata kumulatif kelas-0  mu(k)
    muT = mu(end);                     % rerata global
    % sigma_B^2(k) = (muT*w0 - mu)^2 / (w0 * (1 - w0))
    denom = omega .* (1 - omega);
    sigmaB = zeros(bins, 1);
    ok = denom > 0;
    sigmaB(ok) = (muT * omega(ok) - mu(ok)).^2 ./ denom(ok);

    [~, kStar] = max(sigmaB);          % split terbaik: bin 1..kStar jadi background
    T = (kStar - 1 + 0.5) / (bins - 1) * vmax;   % balik ke satuan kekuatan (tepi bin)
end
