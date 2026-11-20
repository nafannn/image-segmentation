function out = myConv2(I, K)
%MYCONV2 Convolution 2-D yang ditulis dari nol ('same', border replikasi).
%   out = myConv2(I, K) meng-convolve citra gray I (tipe numerik apa pun)
%   dengan kernel K dan mengembalikan matriks double seukuran I. Ini
%   menggantikan conv2 bawaan yang dipakai di kuliah, supaya semua operator
%   tepi benar-benar buatan sendiri.
%
%   Alih-alih mengulang per piksel (lambat di MATLAB), loop-nya jalan di
%   atas elemen kernel: tiap suku K(i,j) * shifted(I) adalah operasi satu
%   matriks penuh, jadi kernel 3x3 cuma butuh 9 kali tambah-kali matriks.
    I = double(I);
    K = double(K);
    [H, W] = size(I);
    [kr, kc] = size(K);

    % Convolution = korelasi dengan kernel yang diputar 180 derajat
    Kf = rot90(K, 2);

    % Padding sebelum/sesudah supaya "pusat" kernel mendarat di tiap piksel.
    % Untuk ukuran genap (Roberts 2x2) sisa baris/kolom ditaruh di belakang.
    padTop  = floor((kr - 1) / 2);  padBottom = kr - 1 - padTop;
    padLeft = floor((kc - 1) / 2);  padRight  = kc - 1 - padLeft;

    % Padding replikasi lewat indeks yang dijepit (tanpa perlu padarray)
    rowIdx = [ones(1, padTop),  1:H, H * ones(1, padBottom)];
    colIdx = [ones(1, padLeft), 1:W, W * ones(1, padRight)];
    P = I(rowIdx, colIdx);

    out = zeros(H, W);
    for i = 1:kr
        for j = 1:kc
            w = Kf(i, j);
            if w ~= 0   % koefisien nol tidak menyumbang, jadi dilewati
                out = out + w * P(i:i + H - 1, j:j + W - 1);
            end
        end
    end
end
