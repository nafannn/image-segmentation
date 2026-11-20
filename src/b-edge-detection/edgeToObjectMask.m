function [mask, info] = edgeToObjectMask(E, closeRadius, minArea, keepN, clearBorder)
%EDGETOOBJECTMASK Bentuk mask objek dari binary edge map.
%   [mask, info] = edgeToObjectMask(E, closeRadius, minArea, keepN, clearBorder)
%     E           : edge map logical
%     closeRadius : radius (px) disk yang dipakai menyambung celah antar edge
%     minArea     : region lebih kecil dari ini (px) dibuang sebagai noise
%     keepN       : jumlah region terbesar yang disimpan sebagai "objek utama"
%     clearBorder : true -> buang region yang menyentuh border citra
%                   (tekstur padat/latar menyentuh, objek biasanya tidak)
%
%   Bentuk objek diambil dari edge-nya: garis luar objek adalah kurva
%   tertutup. Begitu kurvanya menutup, bagian dalamnya bisa diisi sehingga
%   objek terpisah dari latar.
%     1. Closing (dilate lalu erode) menyambung potongan edge yang terputus
%        supaya garis luarnya jadi kurva tertutup.
%     2. Hole filling mengubah tiap kurva tertutup jadi region padat.
%     3. Opening membuang sisa garis edge tipis yang tidak mengurung apa pun
%        (tekstur, edge terisolasi), sementara region padat tetap utuh.
%     4. Opsional: buang region yang menyentuh border, buang region kecil,
%        lalu simpan hanya keepN region terbesar.
    if nargin < 5
        clearBorder = false;
    end
    E = logical(E);
    info = struct('NumCandidates', 0, 'KeptAreas', [], 'BorderFallback', false);

    % 1) Tutup celah di sepanjang garis luar
    if closeRadius > 0
        se = strel('disk', round(closeRadius), 0);
        closed = imclose(E, se);
    else
        closed = E;
    end

    % 2) Isi bagian dalam tiap contour yang sudah tertutup
    filled = imfill(closed, 'holes');

    % 3) Opening dengan disk yang sama membuang garis yang lebih tipis
    if closeRadius > 0
        filled = imopen(filled, se);
    end

    % 4) Buang blob di border dan blob kecil, sisakan N component terbesar.
    % Pada citra bertekstur padat, contour yang menutup hampir seluruh citra
    % membuat SEMUA region menyentuh tepi; kalau filter border diterapkan apa
    % adanya, mask jadi kosong dan panel segmentasi hitam. Karena itu filter
    % border hanya dipakai bila masih ada yang bertahan setelah filter luas --
    % kalau tidak, mask diambil tanpa filter border dan info.BorderFallback =
    % true supaya GUI/laporan bisa menyebut kejadian ini apa adanya.
    if clearBorder
        candidates = dropBorderRegions(filled, 5);
    else
        candidates = filled;
    end
    if minArea > 0
        candidates = bwareaopen(candidates, round(minArea));
    end
    if clearBorder && ~any(candidates(:))
        info.BorderFallback = true;
        candidates = filled;
        if minArea > 0
            candidates = bwareaopen(candidates, round(minArea));
        end
    end
    filled = candidates;
    [lbl, n] = bwlabel(filled, 8);
    info.NumCandidates = n;
    mask = false(size(E));
    if n == 0
        return;
    end
    areas = accumarray(lbl(lbl > 0), 1, [n 1]);     % jumlah piksel per region
    [areas, order] = sort(areas, 'descend');
    keep = order(1:min(round(keepN), n));
    mask = ismember(lbl, keep);
    info.KeptAreas = areas(1:numel(keep))';
end

function bw = dropBorderRegions(bw, margin)
% Buang setiap connected component yang punya piksel dalam jarak `margin` px
% dari border citra. Margin (bukan harus tepat menyentuh) perlu karena
% beberapa detektor, misalnya Canny, tidak pernah menandai piksel terluar
% sebagai edge.
    [lbl, n] = bwlabel(bw, 8);
    if n == 0
        return;
    end
    band = true(size(bw));
    band(margin + 1:end - margin, margin + 1:end - margin) = false;   % frame setebal margin
    touching = unique(lbl(band & lbl > 0));
    bw(ismember(lbl, touching)) = false;
end
