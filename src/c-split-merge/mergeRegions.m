function [L, info] = mergeRegions(L, G, valid, key, Tmerge, minRegion, maxIter)
%MERGEREGIONS Tahap merge: gabungkan region bertetangga yang gabungannya homogen.
%   [L, info] = mergeRegions(L, G, valid, key, Tmerge, minRegion, maxIter)
%     L         : peta label hasil quadSplit
%     G         : citra gray double yang sudah di-pad (seukuran L)
%     valid     : logical, false = piksel padding
%     key       : predikat homogenitas ('range' / 'std'), sama dengan tahap split
%     Tmerge    : threshold homogenitas untuk GABUNGAN dua region
%     minRegion : region dengan luas < ini diserap ke tetangga termirip (0 = nonaktif)
%     maxIter   : batas jumlah pass merge (default 12)
%
%   Alur (region adjacency graph + union-find):
%     1. Semua pasangan region bertetangga dikumpulkan sekali (regionAdjacency).
%     2. Setiap pass: pasangan diurutkan naik menurut |mean1 - mean2| sehingga
%        region yang paling mirip dicoba lebih dulu, lalu digabung bila predikat
%        homogenitas pada gabungannya masih lolos. Statistik gabungan cukup
%        penjumlahan N, S, S2 dan min/max (tidak perlu menghitung ulang piksel).
%     3. Pass diulang selama masih ada penggabungan.
%     4. Region yang lebih kecil dari minRegion diserap ke tetangga dengan
%        rata-rata paling dekat, supaya tidak ada bercak kecil yang tersisa.
%
%   Catatan: predikat diuji pada gabungan, bukan pada masing-masing region.
%   Inilah yang membuat "merge" berbeda dari sekadar menggabungkan region yang
%   sudah homogen: dua region homogen yang kontrasnya besar tetap dipisahkan.
    if nargin < 7 || isempty(maxIter)
        maxIter = 12;
    end
    if nargin < 6 || isempty(minRegion)
        minRegion = 0;
    end
    if nargin < 5 || isempty(Tmerge)
        Tmerge = 0;
    end
    if nargin < 3 || isempty(valid)
        valid = true(size(L));
    end

    % Statistik awal tiap blok daun
    N0 = max([L(:); 1]);
    st = regionStats(L, G, valid);

    parent = 1:N0;          % union-find: parent(k) = 1 untuk akar
    rootN = st.N;
    rootS = st.S;
    rootS2 = st.S2;
    rootMin = st.Min;
    rootMax = st.Max;

    [pairs, ~] = regionAdjacency(L, valid);

    mergeCount = 0;
    passes = 0;
    if ~isempty(pairs)
        for pass = 1:maxIter
            passes = pass;

            % Pasangan pada pass ini, dilihat lewat akar union-find terkini
            ra = findRoot(parent, pairs(:, 1));
            rb = findRoot(parent, pairs(:, 2));
            keep = ra ~= rb;
            if ~any(keep)
                break;
            end
            pa = pairs(keep, :);
            ra = ra(keep);
            rb = rb(keep);

            % Urutkan dari yang paling mirip: perbedaan rata-rata terkecil dulu
            ma = rootS(ra) ./ max(rootN(ra), 1);
            mb = rootS(rb) ./ max(rootN(rb), 1);
            [~, order] = sort(abs(ma - mb), 'ascend');

            merged = 0;
            for i = 1:numel(order)
                k = order(i);
                a = findRoot(parent, pa(k, 1));
                b = findRoot(parent, pa(k, 2));
                if a == b
                    continue;               % sudah tergabung lewat pasangan lain
                end
                if unionHomogeneous(a, b, key, Tmerge, rootN, rootS, rootS2, rootMin, rootMax)
                    % Gabungkan b ke a: statistik cukup dijumlahkan
                    rootN(a) = rootN(a) + rootN(b);
                    rootS(a) = rootS(a) + rootS(b);
                    rootS2(a) = rootS2(a) + rootS2(b);
                    rootMin(a) = min(rootMin(a), rootMin(b));
                    rootMax(a) = max(rootMax(a), rootMax(b));
                    parent(b) = a;
                    merged = merged + 1;
                end
            end

            mergeCount = mergeCount + merged;
            if merged == 0
                break;                      % stabil: tidak ada lagi yang bisa digabung
            end
        end
    end

    % Rapatkan nomor label 1..K setelah penggabungan
    L = remapLabels(L, parent);

    % Serap region kecil (< minRegion) ke tetangga yang paling mirip
    absorbed = 0;
    if minRegion > 0
        for p = 1:8
            st = regionStats(L, G, valid);
            small = find(st.N > 0 & st.N < minRegion);
            if isempty(small)
                break;
            end
            [pairs2, ~] = regionAdjacency(L, valid);
            K = numel(st.N);
            par = 1:K;
            moved = 0;
            for s = small(:)'
                if st.N(s) <= 0 || st.N(s) >= minRegion
                    continue;               % sudah diserap pada iterasi ini
                end
                nb = pairs2(pairs2(:, 1) == s | pairs2(:, 2) == s, :);
                nb = unique(nb(:));
                nb(nb == s) = [];
                nb = nb(st.N(nb) > 0);
                if isempty(nb)
                    continue;               % region terisolasi: biarkan
                end
                [~, k] = min(abs(st.Mean(nb) - st.Mean(s)));
                t = nb(k);
                ra = findRoot(par, s);
                rb = findRoot(par, t);
                if ra == rb
                    continue;
                end
                par(rb) = ra;
                st.N(ra) = st.N(ra) + st.N(rb);
                st.S(ra) = st.S(ra) + st.S(rb);
                st.Mean(ra) = st.S(ra) / st.N(ra);
                st.N(rb) = 0;               % tandai sudah diserap
                st.S(rb) = 0;
                moved = moved + 1;
            end
            if moved == 0
                break;
            end
            absorbed = absorbed + moved;
            L = remapLabels(L, par);
        end
    end

    info.NumRegions = max([L(:); 0]);
    info.MergeCount = mergeCount;
    info.Passes = passes;
    info.Absorbed = absorbed;
end

% -------------------------------------------------------------------------
function r = findRoot(parent, x)
%FINDROOT Cari akar himpunan pada union-find (bisa vektor).
    r = x(:);
    while any(parent(r) ~= r)
        r = parent(r);
    end
end

% -------------------------------------------------------------------------
function ok = unionHomogeneous(a, b, key, T, N, S, S2, Mn, Mx)
%UNIONHOMOGENEOUS Uji predikat homogenitas pada GABUNGAN region a dan b.
    switch lower(key)
        case 'range'
            lo = min(Mn(a), Mn(b));         % min gabungan
            hi = max(Mx(a), Mx(b));         % max gabungan
            ok = (hi - lo) <= T;
        case 'std'
            n = N(a) + N(b);
            if n <= 0
                ok = false;
                return;
            end
            mu = (S(a) + S(b)) / n;
            v = max((S2(a) + S2(b)) / n - mu ^ 2, 0);
            ok = sqrt(v) <= T;
        otherwise
            error('mergeRegions:key', 'Predikat homogenitas tidak dikenal: "%s".', key);
    end
end

% -------------------------------------------------------------------------
function L = remapLabels(L, parent)
%REMAPLABELS Ubah label lama menjadi 1..K' yang rapat mengikuti union-find.
    K = numel(parent);
    r = findRoot(parent, (1:K)');
    [~, ~, j] = unique(r);              % j(k) = nomor baru untuk label k
    lut = [0; j(:)];                    % indeks 1 untuk label 0 (padding)
    L = lut(L + 1);
end
