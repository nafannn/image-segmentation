function [labelMap, depthMap, info] = quadSplit(P, valid, key, Tsplit, minBlock)
%QUADSPLIT Tahap split: quadtree divide and conquer atas citra ber-padding.
%   [labelMap, depthMap, info] = quadSplit(P, valid, key, Tsplit, minBlock)
%     P        : citra gray double yang sudah di-pad ke pangkat dua
%     valid    : logical seukuran P (false = piksel padding)
%     key      : predikat homogenitas ('range' atau 'std')
%     Tsplit   : threshold homogenitas
%     minBlock : ukuran sisi blok terkecil yang boleh dibentuk (px)
%
%   labelMap : setiap blok daun (blok yang berhenti dipecah) diberi label
%              1..K; piksel padding yang tidak tercakup blok valid = 0
%   depthMap : level quadtree setiap piksel (0 = akar), untuk menampilkan grid
%   info     : Depth, NumLevels, BlocksPerLevel, NumBlocks
%
%   Algoritma: mulai dari satu blok sebesar citra. Pada setiap level, seluruh
%   blok kandidat diuji homogenitasnya secara serentak (blockStatistics). Blok
%   yang homogen BERHENTI dan menjadi region (blok daun). Blok yang belum
%   homogen dipecah menjadi 4 anak dan menjadi kandidat pada level berikutnya,
%   kecuali ukurannya sudah kurang dari 2*minBlock (anak akan lebih kecil dari
%   minBlock) -- blok seperti itu tetap dijadikan daun supaya tetap tersegmentasi.
    if nargin < 5 || isempty(minBlock)
        minBlock = 4;
    end
    minBlock = max(1, round(minBlock));

    [Hp, Wp] = size(P);
    if 2 ^ round(log2(Hp)) ~= Hp || 2 ^ round(log2(Wp)) ~= Wp
        error('quadSplit:notPadded', ...
            'quadSplit butuh citra ber-padding pangkat dua (pakai padToPowerOfTwo).');
    end
    if nargin < 2 || isempty(valid)
        valid = true(Hp, Wp);
    end

    labelMap = zeros(Hp, Wp);
    depthMap = zeros(Hp, Wp);

    h = Hp;
    w = Wp;
    level = 0;
    cand = true;                 % level 0: hanya satu blok (akar)
    blocksPerLevel = zeros(1, 16);
    nextLabel = 0;

    while true
        nbh = Hp / h;
        nbw = Wp / w;

        % Statistik + uji homogenitas seluruh blok pada level ini
        st = blockStatistics(P, h, w, valid);
        homogeneous = homogeneityTest(st, key, Tsplit);
        usable = st.N > 0;                          % blok yang punya piksel asli
        canSplit = (h >= 2 * minBlock) && (w >= 2 * minBlock);

        % Blok daun: sudah homogen, atau sudah tidak boleh dipecah lagi
        leaf = cand & usable & (homogeneous | ~canSplit);
        nLeaf = nnz(leaf);
        if nLeaf > 0
            ids = zeros(nbh, nbw);
            ids(leaf) = nextLabel + (1:nLeaf);
            nextLabel = nextLabel + nLeaf;

            % Cap label ke seluruh piksel blok (kron = "perbesar" tiap sel)
            Lexp = kron(ids, ones(h, w));
            sel = Lexp > 0;
            labelMap(sel) = Lexp(sel);
            depthMap(sel) = level;
        end
        blocksPerLevel(level + 1) = nLeaf;

        % Blok yang harus dipecah menjadi 4 anak pada level berikutnya
        child = cand & usable & ~homogeneous & canSplit;
        if ~any(child(:)) || level >= 15
            break;
        end
        cand = repelem(child, 2, 2);               % tiap anak mewarisi status induk
        h = h / 2;
        w = w / 2;
        level = level + 1;
    end

    info.Depth = level;
    info.NumLevels = level + 1;
    info.BlocksPerLevel = blocksPerLevel(1:level + 1);
    info.NumBlocks = nextLabel;
end
