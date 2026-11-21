function M = gradientMagnitude(Gx, Gy, mode)
%GRADIENTMAGNITUDE Kekuatan edge (gradient magnitude) dari dua komponen.
%   M = gradientMagnitude(Gx, Gy, mode)
%     mode 1 : sqrt(Gx^2 + Gy^2)  -> rumus eksak
%     mode 2 : |Gx| + |Gy|        -> aproksimasi tanpa akar
%     mode 3 : max(|Gx|, |Gy|)    -> aproksimasi paling murah
%
%   Varian 2 dan 3 dipakai kalau biaya hitung lebih penting: akar kuadrat
%   dianggap terlalu mahal dan hasilnya hanya beda konstanta penskalaan.
%   Ketiganya diekspos di GUI supaya bisa dibandingkan (jumlah piksel tepi,
%   presisi, recall, IoU mask objek).
    mode = round(mode);
    switch mode
        case 1
            M = sqrt(Gx .^ 2 + Gy .^ 2);
        case 2
            M = abs(Gx) + abs(Gy);
        case 3
            M = max(abs(Gx), abs(Gy));
        otherwise
            error('gradientMagnitude:mode', ...
                'Mode magnitude tidak dikenal: %g (pakai 1, 2, atau 3).', mode);
    end
end
