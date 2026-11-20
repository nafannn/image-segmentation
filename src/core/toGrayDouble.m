function G = toGrayDouble(img)
%TOGRAYDOUBLE Convert an RGB or gray image to a double gray image in [0, 255].
%   Uses the ITU-R BT.601 luminance weights (same as rgb2gray). Keeping
%   the 0-255 scale makes thresholds comparable with the lecture examples.
    if islogical(img)
        img = uint8(img) * 255;
    end
    if isinteger(img) && ~isa(img, 'uint8')
        img = double(img) / double(intmax(class(img))) * 255;   % e.g. uint16 -> 0..255
    elseif isfloat(img) && max(img(:)) <= 1
        img = double(img) * 255;                              % [0,1] float -> 0..255
    end
    img = double(img);
    if size(img, 3) == 3
        G = 0.299 * img(:, :, 1) + 0.587 * img(:, :, 2) + 0.114 * img(:, :, 3);
    else
        G = img(:, :, 1);
    end
end
