function G = toGrayDouble(img)
%TOGRAYDOUBLE Ubah citra RGB atau gray jadi citra gray double di [0, 255].
%   Bobot luminansi ITU-R BT.601 dipakai (sama seperti rgb2gray). Skala
%   0-255 dipertahankan supaya threshold di GUI, script, dan laporan memakai
%   satuan yang sama.
    if islogical(img)
        img = uint8(img) * 255;
    end
    if isinteger(img) && ~isa(img, 'uint8')
        img = double(img) / double(intmax(class(img))) * 255;   % mis. uint16 -> 0..255
    elseif isfloat(img) && max(img(:)) <= 1
        img = double(img) * 255;                              % float [0,1] -> 0..255
    end
    img = double(img);
    if size(img, 3) == 3
        G = 0.299 * img(:, :, 1) + 0.587 * img(:, :, 2) + 0.114 * img(:, :, 3);
    else
        G = img(:, :, 1);
    end
end
