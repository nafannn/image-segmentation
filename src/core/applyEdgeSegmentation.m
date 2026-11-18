function [R, info] = applyEdgeSegmentation(img, methodKey, params, thr, segParams) %#ok<INUSD,STOUT>
%APPLYEDGESEGMENTATION Part B pipeline used by the GUI and scripts.
%   img       : input image (RGB or gray)
%   methodKey : operator key from edgeRegistry ('sobel', 'log', ...)
%   params    : operator parameters (struct, from the registry)
%   thr       : struct with fields Mode ('otsu'|'percentile'|'manual') and Value
%   segParams : struct with closeRadius, minArea, keepN
%
%   R    : struct with fields Response, Edges, Mask, Segmented, Overlay
%   info : struct with fields Label, ParamStr
%
%   TODO (Step 2-3): implement operators and edge -> object mask.
    error('applyEdgeSegmentation:notImplemented', ...
        'Edge detection & segmentation belum diimplementasi (Step 2-3).');
end
