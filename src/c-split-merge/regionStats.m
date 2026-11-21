function st = regionStats(L, G, valid)
%REGIONSTATS Statistik intensitas tiap label region (skala 0-255).
%   st = regionStats(L, G, valid)
%     L     : peta label (0 = bukan region)
%     G     : citra gray double seukuran L
%     valid : logical seukuran L, false = piksel padding (diabaikan)
%
%   Keluaran berupa vektor kolom sepanjang K = max(L(:)):
%     st.N, st.S, st.S2, st.Mean, st.Var, st.Std, st.Min, st.Max, st.Range
%   Semuanya dihitung dengan ACCUMARRAY, jadi satu kali lewat citra dan tanpa
%   loop per region. Statistik inilah yang dipakai tahap merge: statistik
%   gabungan dua region cukup penjumlahan N, S, dan S2.
    if nargin < 3 || isempty(valid)
        valid = true(size(L));
    end
    K = max([L(:); 1]);

    % Hanya piksel bertanda region dan bukan padding yang ikut dihitung
    mask = valid & (L > 0);
    idx = double(L(mask));
    g = double(G(mask));

    st.N = accumarray(idx, 1, [K 1]);
    st.S = accumarray(idx, g, [K 1]);
    st.S2 = accumarray(idx, g .^ 2, [K 1]);

    % Ekstrem per region. Hanya label yang benar-benar punya piksel yang dihitung
    % (accumarray dengan @min/@max tidak boleh diberi bin kosong), lalu disebar
    % kembali ke nomor label aslinya lewat `present`.
    hasPix = st.N > 0;
    st.Min = zeros(K, 1);
    st.Max = zeros(K, 1);
    if any(hasPix)
        present = find(hasPix);
        [~, ~, ic] = unique(idx);
        st.Min(present) = accumarray(ic, g, [], @min);
        st.Max(present) = accumarray(ic, g, [], @max);
    end

    n = max(st.N, 1);
    st.Mean = st.S ./ n;
    st.Var = max(st.S2 ./ n - st.Mean .^ 2, 0);
    st.Std = sqrt(st.Var);
    st.Range = st.Max - st.Min;

    % Region tanpa piksel valid: netralkan supaya tidak memengaruhi merge
    st.Min(~hasPix) = 0;
    st.Max(~hasPix) = 0;
    st.Mean(~hasPix) = 0;
    st.Var(~hasPix) = 0;
    st.Std(~hasPix) = 0;
    st.Range(~hasPix) = 0;
    st.Area = st.N;
end
