function [R, info] = applySplitMerge(img, predicateKey, params) %#ok<INUSD,STOUT>
%APPLYSPLITMERGE Part C pipeline used by the GUI and scripts.
%   img          : input image (RGB or gray)
%   predicateKey : 'range' or 'std' (see splitMergeRegistry)
%   params       : struct with Tsplit, minBlock, Tmerge, minRegion
%
%   R    : struct with fields
%            SplitGrid  - input with quadtree block borders drawn
%            SplitMean  - every split block filled with its mean color
%            MergedMean - every merged region filled with its mean color
%            LabelColor - merged regions in pseudo-colors
%            Boundary   - input with merged region borders drawn
%   info : struct with fields Label, ParamStr, Summary (cellstr of stats)
%
%   TODO (Step 4): implement quadtree split + region merge.
    error('applySplitMerge:notImplemented', ...
        'Split and merge belum diimplementasi (Step 4).');
end
