function m = panelMontage(views, titles, outPath)
%PANELMONTAGE Susun beberapa view menjadi satu gambar panel untuk laporan.
%   m = panelMontage(views, titles, outPath)
%     views   : cell array citra (gray/RGB, logical, atau double 0..1)
%     titles  : cell array judul tiap panel (caption di atas panel)
%     outPath : kalau diberikan, hasil ditulis ke PNG tersebut
%
%   Semua view distandarkan ke uint8 RGB lalu ditempel berjajar dengan jarak
%   dan caption bar gelap, sehingga satu berkas PNG bisa langsung dipakai
%   sebagai gambar laporan (mis. "asli | respons | tepi | mask | segmentasi |
%   kontur"). Panel diasumsikan berukuran sama.
    if nargin < 3
        outPath = '';
    end
    gap = 8;
    capH = 30;

    n = numel(views);
    imgs = cell(1, n);
    for i = 1:n
        v = views{i};
        if isempty(v)
            v = uint8(zeros(1, 1, 3));
        end
        if size(v, 3) == 1
            v = repmat(v, 1, 1, 3);
        end
        imgs{i} = im2uint8(v);
    end

    H = size(imgs{1}, 1);
    W = size(imgs{1}, 2);
    m = uint8(zeros(H + capH, n * W + (n - 1) * gap, 3));

    for i = 1:n
        x0 = (i - 1) * (W + gap) + 1;

        % Caption bar: latar gelap + teks putih (kalau Computer Vision
        % Toolbox tersedia)
        cap = uint8(zeros(capH, W, 3)) + 26;
        if nargin >= 2 && numel(titles) >= i && ~isempty(titles{i})
            try
                cap = insertText(cap, [8 5], titles{i}, 'FontSize', 15, ...
                    'TextColor', 'white', 'BoxOpacity', 0, 'Font', 'Arial');
            catch
                % tanpa toolbox teks: bar dibiarkan kosong, judul tetap
                % dicantumkan di caption laporan
            end
        end
        m(1:capH, x0:x0 + W - 1, :) = cap;
        m(capH + 1:capH + H, x0:x0 + W - 1, :) = imgs{i};
    end

    if ~isempty(outPath)
        imwrite(m, outPath);
    end
    if nargout == 0
        clear m
    end
end
