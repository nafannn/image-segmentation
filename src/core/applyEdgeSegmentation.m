function [R, info] = applyEdgeSegmentation(img, methodKey, params, thr, segParams)
%APPLYEDGESEGMENTATION Pipeline Bagian B yang dipakai GUI dan script.
%   img       : citra masukan (RGB atau gray)
%   methodKey : key operator dari edgeRegistry ('sobel', 'log', ...)
%   params    : parameter operator (struct, dari registry)
%   thr       : struct berisi Mode ('otsu'|'percentile'|'manual') dan Value
%   segParams : preSigma, closeRadius, minArea, keepN, clearBorder
%
%   R    : struct dengan field
%            Response  - keluaran operator diskalakan ke [0,1] untuk tampilan
%            Edges     - peta tepi logical
%            Mask      - mask objek logical
%            Segmented - piksel objek di atas latar hitam
%            Overlay   - citra masukan dengan kontur objek digambar
%   info : struct dengan field Label, ParamStr, Threshold, NumObjects
    G = toGrayDouble(img);
    T = NaN;
    segParams = withDefaults(segParams);

    % Pre-smoothing opsional: blur Gaussian membuang tekstur halus (rumput,
    % salju, bata) yang kalau dibiarkan memunculkan banyak tepi pendek
    if segParams.preSigma > 0
        G = myConv2(G, gaussianKernel(segParams.preSigma));
    end

    switch methodKey
        case {'roberts', 'prewitt', 'sobel'}
            % Orde satu: magnitude gradien, tepi di tempat magnitude >= T.
            % Varian kekuatan tepi dipilih lewat parameter `mag`.
            op = str2func([methodKey 'Edge']);
            [~, Gx, Gy] = op(G);
            magMode = 1;
            if isfield(params, 'mag') && ~isempty(params.mag)
                magMode = round(params.mag);
            end
            M = gradientMagnitude(Gx, Gy, magMode);
            [E, T] = thresholdMagnitude(M, thr.Mode, thr.Value);
            response = M / max(max(M(:)), eps);
            switch magMode
                case 1, opStr = '';
                case 2, opStr = 'G = |Gx|+|Gy|';
                otherwise, opStr = 'G = max(|Gx|,|Gy|)';
            end

        case {'laplace', 'log'}
            % Orde dua: tepi di titik zero-crossing yang slope-nya > T
            if strcmp(methodKey, 'laplace')
                L = laplaceEdge(G, params.neighbors);
                opStr = sprintf('%d-neighbor', params.neighbors);
            else
                L = logEdge(G, params.sigma);
                opStr = sprintf('sigma=%g', params.sigma);
            end
            [S, Z] = zeroCrossing(L);
            [E, T] = thresholdMagnitude(S, thr.Mode, thr.Value, Z);
            % Respons bertanda dipetakan ke gray: 0.5 = nol, gelap = negatif,
            % terang = positif
            response = 0.5 + L / (2 * max(max(abs(L(:))), eps));

        case 'canny'
            [E, M] = cannyEdge(G, params.low, params.high, params.sigma);
            response = M / max(max(M(:)), eps);
            opStr = sprintf('T1=%g T2=%g sigma=%g', params.low, params.high, params.sigma);

        otherwise
            error('applyEdgeSegmentation:method', 'Unknown edge operator "%s".', methodKey);
    end

    % Peta tepi -> mask objek
    [mask, mInfo] = edgeToObjectMask(E, segParams.closeRadius, segParams.minArea, ...
        segParams.keepN, segParams.clearBorder);

    R.Response = response;
    R.Edges = E;
    R.Mask = mask;
    R.Segmented = applyMask(img, mask);
    R.Overlay = drawContour(img, mask);

    % Ringkasan yang enak dibaca untuk status bar / judul figure
    reg = edgeRegistry();
    info.Label = reg(strcmp({reg.Key}, methodKey)).Label;
    parts = {};
    if ~isempty(opStr)
        parts{end+1} = opStr;
    end
    if ~isnan(T)
        parts{end+1} = sprintf('%s T=%.2f', thr.Mode, T);
    end
    parts{end+1} = sprintf('pre=%g close=%d minArea=%d keep=%d border=%d', segParams.preSigma, ...
        segParams.closeRadius, segParams.minArea, segParams.keepN, segParams.clearBorder);
    if isfield(mInfo, 'BorderFallback') && mInfo.BorderFallback
        parts{end+1} = 'border fallback (semua region menyentuh tepi)';
    end
    parts{end+1} = sprintf('%d edge px, %d object(s)', nnz(E), numel(mInfo.KeptAreas));
    info.ParamStr = strjoin(parts, '  |  ');
    info.Threshold = T;
    info.NumObjects = numel(mInfo.KeptAreas);
end

function s = withDefaults(s)
% Isi field segmentasi yang belum ada supaya pemanggil lama tetap jalan
    d = struct('preSigma', 0, 'closeRadius', 3, 'minArea', 200, 'keepN', 1, 'clearBorder', 0);
    f = fieldnames(d);
    for i = 1:numel(f)
        if ~isfield(s, f{i})
            s.(f{i}) = d.(f{i});
        end
    end
end

function out = applyMask(img, mask)
% Pertahankan piksel objek, latar dicat hitam
    out = img;
    m = repmat(mask, 1, 1, size(img, 3));
    out(~m) = 0;
end

function out = drawContour(img, mask)
% Gambar outline mask setebal 2 px dengan warna terang di atas citra
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end
    out = im2uint8(img);
    edgeLine = mask & ~imerode(mask, strel('square', 3));   % batas dalam
    edgeLine = imdilate(edgeLine, strel('square', 2));       % tebal 2 px
    color = uint8([255 215 0]);                             % emas
    for c = 1:3
        ch = out(:, :, c);
        ch(edgeLine) = color(c);
        out(:, :, c) = ch;
    end
end
