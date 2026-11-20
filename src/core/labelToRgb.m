function rgb = labelToRgb(L, cmap)
%LABELTORGB Ubah citra label integer menjadi citra RGB.
%   L    : citra label, 0 = tanpa label (digambar hitam), 1..K = region/kelas.
%   cmap : warna K-by-3 dalam [0,1]. Kalau tidak diberikan, dibuat palet acak
%          yang tetap bisa diulang (berguna untuk region split-and-merge).
    L = double(L);
    L(isnan(L)) = 0;
    K = max(L(:));
    if nargin < 2 || isempty(cmap)
        rs = RandStream('mt19937ar', 'Seed', 4073);   % seed tetap -> warna sama tiap run
        cmap = 0.15 + 0.85 * rand(rs, max(K, 1), 3);
    end
    lut = [0 0 0; cmap];                % baris 1 dipakai untuk label 0
    idx = L + 1;                        % geser label supaya 0 -> baris 1
    rgb = zeros([size(L) 3]);
    for c = 1:3
        channel = lut(:, c);
        rgb(:, :, c) = channel(idx);    % lookup per piksel
    end
end
