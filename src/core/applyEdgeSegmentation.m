function [R, info] = applyEdgeSegmentation(img, methodKey, params, thr, segParams)
%APPLYEDGESEGMENTATION Part B pipeline used by the GUI and scripts.
%   img       : input image (RGB or gray)
%   methodKey : operator key from edgeRegistry ('sobel', 'log', ...)
%   params    : operator parameters (struct, from the registry)
%   thr       : struct with fields Mode ('otsu'|'percentile'|'manual') and Value
%   segParams : struct with preSigma, closeRadius, minArea, keepN, clearBorder
%
%   R    : struct with fields
%            Response  - operator output scaled to [0,1] for display
%            Edges     - logical edge map
%            Mask      - logical object mask
%            Segmented - object pixels on a black background
%            Overlay   - input with the object contour drawn
%   info : struct with fields Label, ParamStr, Threshold, NumObjects
    G = toGrayDouble(img);
    T = NaN;
    segParams = withDefaults(segParams);

    % Optional pre-smoothing: a Gaussian blur removes fine texture (grass,
    % snow, bricks) that would otherwise produce many short edges
    if segParams.preSigma > 0
        G = myConv2(G, gaussianKernel(segParams.preSigma));
    end

    switch methodKey
        case {'roberts', 'prewitt', 'sobel'}
            % First order: gradient magnitude, edge where magnitude > T
            op = str2func([methodKey 'Edge']);
            M = op(G);
            [E, T] = thresholdMagnitude(M, thr.Mode, thr.Value);
            response = M / max(max(M(:)), eps);
            opStr = '';

        case {'laplace', 'log'}
            % Second order: edge at zero-crossings whose slope > T
            if strcmp(methodKey, 'laplace')
                L = laplaceEdge(G, params.neighbors);
                opStr = sprintf('%d-neighbor', params.neighbors);
            else
                L = logEdge(G, params.sigma);
                opStr = sprintf('sigma=%g', params.sigma);
            end
            [S, Z] = zeroCrossing(L);
            [E, T] = thresholdMagnitude(S, thr.Mode, thr.Value, Z);
            % Signed response mapped to gray: 0.5 = zero, dark = negative, bright = positive
            response = 0.5 + L / (2 * max(max(abs(L(:))), eps));

        case 'canny'
            [E, M] = cannyEdge(G, params.low, params.high, params.sigma);
            response = M / max(max(M(:)), eps);
            opStr = sprintf('T1=%g T2=%g sigma=%g', params.low, params.high, params.sigma);

        otherwise
            error('applyEdgeSegmentation:method', 'Unknown edge operator "%s".', methodKey);
    end

    % Edge map -> object mask
    [mask, mInfo] = edgeToObjectMask(E, segParams.closeRadius, segParams.minArea, ...
        segParams.keepN, segParams.clearBorder);

    R.Response = response;
    R.Edges = E;
    R.Mask = mask;
    R.Segmented = applyMask(img, mask);
    R.Overlay = drawContour(img, mask);

    % Human-readable summary for the status bar / figure titles
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
    parts{end+1} = sprintf('%d edge px, %d object(s)', nnz(E), numel(mInfo.KeptAreas));
    info.ParamStr = strjoin(parts, '  |  ');
    info.Threshold = T;
    info.NumObjects = numel(mInfo.KeptAreas);
end

function s = withDefaults(s)
% Fill in missing segmentation fields so older callers keep working
    d = struct('preSigma', 0, 'closeRadius', 3, 'minArea', 200, 'keepN', 1, 'clearBorder', 0);
    f = fieldnames(d);
    for i = 1:numel(f)
        if ~isfield(s, f{i})
            s.(f{i}) = d.(f{i});
        end
    end
end

function out = applyMask(img, mask)
% Keep the object pixels, paint the background black
    out = img;
    m = repmat(mask, 1, 1, size(img, 3));
    out(~m) = 0;
end

function out = drawContour(img, mask)
% Draw the 2-px outline of the mask in a bright color on top of the image
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end
    out = im2uint8(img);
    edgeLine = mask & ~imerode(mask, strel('square', 3));   % inner boundary
    edgeLine = imdilate(edgeLine, strel('square', 2));       % 2 px thick
    color = uint8([255 215 0]);                             % gold
    for c = 1:3
        ch = out(:, :, c);
        ch(edgeLine) = color(c);
        out(:, :, c) = ch;
    end
end
