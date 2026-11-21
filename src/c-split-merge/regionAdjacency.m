function [pairs, shared] = regionAdjacency(L, valid)
%REGIONADJACENCY Daftar pasangan region bertetangga (4-konektivitas).
%   [pairs, shared] = regionAdjacency(L, valid)
%     L      : peta label
%     valid  : logical seukuran L, false = piksel padding (tidak dihitung)
%     pairs  : Nx2, tiap baris = dua label region yang berbagi batas
%     shared : Nx1, banyak pasangan piksel yang berbatasan (panjang batas)
%
%   Region adjacency graph (RAG) dibangun dengan membandingkan label antar
%   piksel tetangga kanan dan bawah saja: setiap pasangan yang bersebelahan
%   pasti terhitung tepat sekali, sehingga grafnya tidak dobel.
    if nargin < 2 || isempty(valid)
        valid = true(size(L));
    end
    L = double(L);

    % Tetangga kanan: (r, c) dan (r, c+1)
    a = L(:, 1:end - 1);
    b = L(:, 2:end);
    m = valid(:, 1:end - 1) & valid(:, 2:end) & a > 0 & b > 0 & a ~= b;
    pairs = [a(m), b(m)];

    % Tetangga bawah: (r, c) dan (r+1, c)
    a = L(1:end - 1, :);
    b = L(2:end, :);
    m = valid(1:end - 1, :) & valid(2:end, :) & a > 0 & b > 0 & a ~= b;
    pairs = [pairs; a(m), b(m)];

    if isempty(pairs)
        pairs = zeros(0, 2);
        shared = zeros(0, 1);
        return;
    end

    % Urutkan tiap baris (a,b) -> (min,max) supaya (a,b) dan (b,a) sama,
    % lalu hitung berapa kali pasangan itu muncul = panjang batas bersama
    pairs = sort(pairs, 2);
    [pairs, ~, ic] = unique(pairs, 'rows');
    shared = accumarray(ic, 1);
end
