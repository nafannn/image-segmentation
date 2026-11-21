function [P, valid] = padToPowerOfTwo(G)
%PADTOPOWEROFTWO Perbesar citra ke pangkat dua terdekat (padding replikasi).
%   [P, valid] = padToPowerOfTwo(G)
%     G     : citra gray double
%     P     : citra hasil padding, ukurannya pangkat dua pada kedua sisi
%     valid : logical seukuran P, true untuk piksel asli
%
%   Quadtree membagi blok menjadi 4 anak sama besar di setiap level. Citra
%   BSDS500 berukuran 481x321 (bukan pangkat dua), sehingga tanpa padding level
%   quadtree akan berisi blok dengan ukuran tidak seragam dan statistik blok
%   tidak bisa dihitung serentak. Padding replikasi (piksel tepi diulang)
%   menjaga statistik blok di pinggir tetap mirip isi citra aslinya; piksel
%   padding sendiri ditandai oleh `valid` dan diabaikan saat merge, rendering,
%   maupun perhitungan statistik.
    [H, W] = size(G);
    Hp = 2 ^ ceil(log2(H));
    Wp = 2 ^ ceil(log2(W));

    % Indeks piksel yang diulang di tepi kanan dan bawah
    rowIdx = [1:H, H * ones(1, Hp - H)];
    colIdx = [1:W, W * ones(1, Wp - W)];
    P = G(rowIdx, colIdx);

    valid = false(Hp, Wp);
    valid(1:H, 1:W) = true;
end
