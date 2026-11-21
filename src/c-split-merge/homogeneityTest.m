function ok = homogeneityTest(st, key, T)
%HOMOGENEITYTEST Uji predikat homogenitas pada satu atau banyak blok sekaligus.
%   ok = homogeneityTest(st, key, T)
%     st  : struct statistik dari blockStatistics/regionStats, memakai field
%           Range (max - min) dan Std (simpangan baku), keduanya pada skala 0-255
%     key : 'range' -> blok homogen bila max - min <= T
%           'std'   -> blok homogen bila simpangan baku <= T
%     T   : threshold (Tsplit saat split, Tmerge saat merge)
%     ok  : logical seukuran st.Range
%
%   Kedua predikat memakai skala intensitas yang sama, jadi satu threshold T
%   bisa dibandingkan antar citra. Predikat 'range' peka terhadap satu pasang
%   piksel ekstrem, sedangkan 'std' memakai seluruh sebaran nilai; perbedaan
%   inilah yang dianalisis pada laporan.
    switch lower(key)
        case 'range'
            ok = st.Range <= T;
        case 'std'
            ok = st.Std <= T;
        otherwise
            error('homogeneityTest:key', ...
                'Predikat homogenitas tidak dikenal: "%s".', key);
    end
end
