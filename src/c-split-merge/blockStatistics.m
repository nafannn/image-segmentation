function st = blockStatistics(P, h, w, valid)
%BLOCKSTATISTICS Statistik semua blok h x w pada satu level quadtree.
%   st = blockStatistics(P, h, w, valid)
%     P     : citra gray double hasil padding (ukuran kelipatan h dan w)
%     h, w  : ukuran blok pada level ini
%     valid : logical seukuran P, true untuk piksel asli (false = padding)
%
%   Keluaran (matriks nbh x nbw, indeks = baris/kolom blok):
%     st.N, st.S, st.S2       jumlah piksel valid, jumlah nilai, jumlah kuadrat
%     st.Mean, st.Var, st.Std rata-rata, variansi, simpangan baku
%     st.Min, st.Max, st.Range nilai minimum, maksimum, dan kontras (max - min)
%
%   Blok pada satu level membentuk grid seragam, sehingga statistik SELURUH
%   blok bisa dihitung sekali jalan: P di-RESHAPE menjadi (h x nbh x w x nbw)
%   lalu direduksi pada dimensi 1 dan 3. Tidak ada loop per blok dan tidak
%   perlu integral image; cara ini eksak untuk semua ukuran blok.
    [Hp, Wp] = size(P);
    nbh = Hp / h;
    nbw = Wp / w;

    % Susun ulang agar tiap blok menjadi "irisan" 4-D
    B = reshape(P, h, nbh, w, nbw);
    V = reshape(double(valid), h, nbh, w, nbw);
    Bv = B .* V;                      % piksel padding dibuat 0 -> tidak menyumbang

    st.N = squeeze(sum(sum(V, 1), 3));
    st.S = squeeze(sum(sum(Bv, 1), 3));
    st.S2 = squeeze(sum(sum(Bv .^ 2, 1), 3));

    % Min/max tidak bisa lewat penjumlahan: piksel padding diganti +-Inf supaya
    % tidak pernah terpilih sebagai ekstrem blok
    Bmin = B;
    Bmin(~V) = Inf;
    st.Min = squeeze(min(min(Bmin, [], 1), [], 3));
    Bmax = B;
    Bmax(~V) = -Inf;
    st.Max = squeeze(max(max(Bmax, [], 1), [], 3));

    n = max(st.N, 1);                 % hindari bagi nol untuk blok penuh padding
    st.Mean = st.S ./ n;
    st.Var = max(st.S2 ./ n - st.Mean .^ 2, 0);   % variansi, dijepit di 0 (galat pembulatan)
    st.Std = sqrt(st.Var);
    st.Range = st.Max - st.Min;

    % Blok yang seluruhnya padding tidak dipakai; nilai netral agar predikat
    % homogenitas menganggapnya "homogen" dan blok itu tidak dipecah sia-sia
    empty = st.N == 0;
    st.Mean(empty) = 0;
    st.Std(empty) = 0;
    st.Var(empty) = 0;
    st.Range(empty) = 0;
    st.Min(empty) = 0;
    st.Max(empty) = 0;
end
