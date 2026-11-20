function [R, info] = applySplitMerge(img, predicateKey, params)
%APPLYSPLITMERGE Pipeline Bagian C yang dipakai GUI dan script.
%   img          : citra masukan (RGB atau gray)
%   predicateKey : 'range' atau 'std' (lihat splitMergeRegistry)
%   params       : struct dengan Tsplit, minBlock, Tmerge, minRegion
%
%   R    : struct dengan field
%            SplitGrid  - citra masukan dengan garis batas blok quadtree
%            SplitMean  - tiap blok split diisi warna rata-ratanya
%            MergedMean - tiap region hasil merge diisi warna rata-ratanya
%            LabelColor - region hasil merge dalam pseudo-color
%            Boundary   - citra masukan dengan garis batas region hasil merge
%   info : struct dengan field Label, ParamStr, Summary (cellstr statistik)
%          plus field numerik NumRegions, NumBlocks, Depth, Seconds dan peta
%          label SplitMap / MergedMap (untuk script dan metrik laporan).
%
%   Tahapan: padding pangkat dua -> quadtree split (quadSplit) -> merge region
%   bertetangga (mergeRegions) -> render lima view. Citra gray dipakai untuk
%   uji homogenitas; rendering memakai citra asli jadi hasil merge terlihat
%   dalam warna aslinya.
    tStart = tic;
    G = toGrayDouble(img);
    [H, W] = size(G);
    params = withDefaults(params);

    reg = splitMergeRegistry();
    entry = reg(strcmp({reg.Key}, predicateKey));
    if isempty(entry)
        error('applySplitMerge:key', 'Predikat homogenitas tidak dikenal: "%s".', predicateKey);
    end

    % 1) Padding replikasi ke pangkat dua, lalu tahap split (quadtree)
    [P, valid] = padToPowerOfTwo(G);
    [Lsplit, depth, sInfo] = quadSplit(P, valid, predicateKey, params.Tsplit, params.minBlock);

    % 2) Merge: gabungkan region bertetangga yang gabungannya masih homogen
    [Lmerge, mInfo] = mergeRegions(Lsplit, P, valid, predicateKey, ...
        params.Tmerge, params.minRegion);

    % 3) Buang area padding lalu render kelima view
    Ls = Lsplit(1:H, 1:W);
    Lm = Lmerge(1:H, 1:W);
    info.DepthMap = depth(1:H, 1:W);

    R.SplitGrid  = drawBorders(img, regionBorders(Ls, 1), 1);
    R.SplitMean  = fillRegions(img, Ls);
    R.MergedMean = fillRegions(img, Lm);
    R.LabelColor = labelImageToUint8(labelToRgb(Lm));
    R.Boundary   = drawBorders(img, regionBorders(Lm, 2), 1);

    % 4) Ringkasan untuk status bar / panel statistik GUI
    info.Label = entry.Label;
    info.ParamStr = sprintf('Tsplit=%g  Tmerge=%g  minBlock=%d  minRegion=%g', ...
        params.Tsplit, params.Tmerge, params.minBlock, params.minRegion);
    info.Threshold = params.Tsplit;
    info.NumRegions = mInfo.NumRegions;
    info.NumBlocks = sInfo.NumBlocks;
    info.Depth = sInfo.Depth;
    info.MergeCount = mInfo.MergeCount;
    info.Passes = mInfo.Passes;
    info.Absorbed = mInfo.Absorbed;
    info.Seconds = toc(tStart);
    info.SplitMap = Ls;
    info.MergedMap = Lm;
    info.Summary = { ...
        sprintf('Region akhir: %d  (%d blok daun, %d level quadtree)', ...
            mInfo.NumRegions, sInfo.NumBlocks, sInfo.NumLevels), ...
        sprintf('Blok per level: %s', num2str(sInfo.BlocksPerLevel)), ...
        sprintf('Merge: %d pasangan dalam %d pass, serapan region kecil: %d', ...
            mInfo.MergeCount, mInfo.Passes, mInfo.Absorbed), ...
        sprintf('%s  |  waktu %.2f s', info.ParamStr, info.Seconds)};
end

% -------------------------------------------------------------------------
function s = withDefaults(s)
% Lengkapi parameter yang tidak diberikan pemanggil lama
    d = struct('Tsplit', 40, 'minBlock', 4, 'Tmerge', 40, 'minRegion', 0);
    f = fieldnames(d);
    for i = 1:numel(f)
        if ~isfield(s, f{i}) || isempty(s.(f{i}))
            s.(f{i}) = d.(f{i});
        end
    end
end

% -------------------------------------------------------------------------
function out = fillRegions(img, L)
%FILLREGIONS Warnai setiap region dengan rata-rata warna pikselnya.
%   Rata-rata per label dihitung dengan accumarray (satu kali lewat citra),
%   lalu dipakai sebagai lookup table saat mewarnai: hasilnya citra "blocky"
%   yang memperlihatkan isi tiap region tanpa detail aslinya.
    [H, W, C] = size(img);
    L = double(L(1:H, 1:W));
    K = max([L(:); 1]);
    L(L < 1) = K + 1;                    % piksel tanpa label = satu region ekstra
    out = zeros(H, W, C, 'uint8');
    for c = 1:C
        ch = double(img(:, :, c));
        m = accumarray(L(:), ch(:), [K + 1 1], @mean);
        out(:, :, c) = uint8(m(L));
    end
    if C == 1
        out = out(:, :, 1);
    end
end

% -------------------------------------------------------------------------
function out = drawBorders(img, borderMask, thickness)
%DRAWBORDERS Gambar garis batas region di atas citra masukan.
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end
    out = im2uint8(img);
    if thickness > 1
        borderMask = imdilate(borderMask, strel('square', thickness));
    end
    color = uint8([255 215 0]);          % kuning keemasan, sama dengan tab B
    for c = 1:3
        ch = out(:, :, c);
        ch(borderMask) = color(c);
        out(:, :, c) = ch;
    end
end

% -------------------------------------------------------------------------
function b = regionBorders(L, thickness)
%REGIONBORDERS Piksel di perbatasan dua label berbeda (tanpa boundaryMask).
%   Perbedaan label dicek ke tetangga kanan dan bawah saja, jadi tiap batas
%   digambar satu piksel. Ketebalan tambahan memakai dilasi persegi.
    L = double(L);
    b = false(size(L));
    d = L(:, 1:end - 1) ~= L(:, 2:end);
    b(:, 1:end - 1) = b(:, 1:end - 1) | d;
    d = L(1:end - 1, :) ~= L(2:end, :);
    b(1:end - 1, :) = b(1:end - 1, :) | d;
    if thickness > 1
        b = imdilate(b, strel('square', thickness));
    end
end

% -------------------------------------------------------------------------
function out = labelImageToUint8(rgb)
%LABELIMAGETOUINT8 Ubah hasil labelToRgb (double 0..1) ke uint8 supaya
%   tampil benar.
    out = uint8(255 * min(max(rgb, 0), 1));
end
