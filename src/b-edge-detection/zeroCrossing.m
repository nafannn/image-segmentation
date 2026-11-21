function [S, Z] = zeroCrossing(L)
%ZEROCROSSING Cari piksel tempat respons turunan kedua berganti tanda.
%   [S, Z] = zeroCrossing(L)
%     L : respons Laplace / LoG yang bertanda
%     Z : peta logical piksel yang L-nya berganti tanda dengan tetangganya
%     S : kekuatan crossing = |L(p) - L(q)| (kemiringan di titik itu),
%         bernilai 0 kalau tidak ada crossing. Thresholding S membuang
%         crossing lemah akibat noise dan riak intensitas kecil.
%   Tetangga yang dicek: kanan, bawah, bawah-kanan, bawah-kiri. Crossing
%   dibebankan ke piksel yang |L|-nya lebih kecil (lebih dekat ke nol
%   sebenarnya), cara ini menjaga edge tetap setebal satu piksel.
    [H, W] = size(L);
    S = zeros(H, W);
    absL = abs(L);
    offsets = [0 1; 1 0; 1 1; 1 -1];       % [delta baris, delta kolom]

    for k = 1:size(offsets, 1)
        dr = offsets(k, 1);
        dc = offsets(k, 2);
        % Batasi indeks supaya p = (r, c) dan q = (r+dr, c+dc) dua-duanya
        % masih di dalam citra
        r = 1:H - dr;
        if dc >= 0
            c = 1:W - dc;
        else
            c = 1 - dc:W;
        end
        Lp = L(r, c);
        Lq = L(r + dr, c + dc);
        cross = (Lp .* Lq) < 0;             % beda tanda -> ada nol di antaranya
        slope = abs(Lp - Lq) .* cross;

        % Bebankan crossing ke piksel yang lebih dekat ke nol
        toP = cross & (absL(r, c) <= absL(r + dr, c + dc));
        toQ = cross & ~toP;

        Sp = S(r, c);
        Sp(toP) = max(Sp(toP), slope(toP));
        S(r, c) = Sp;

        Sq = S(r + dr, c + dc);
        Sq(toQ) = max(Sq(toQ), slope(toQ));
        S(r + dr, c + dc) = Sq;
    end
    Z = S > 0;
end
