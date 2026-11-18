function [L, classNames, cmap] = segmentSemantic(img) %#ok<INUSD,STOUT>
%SEGMENTSEMANTIC Part D entry point called by the GUI (Semantic tab).
%   *** To be implemented by Person 2 (deep learning). ***
%
%   Contract expected by SegmentationApp:
%     img        : H-by-W-by-3 uint8 RGB image
%     L          : label image (numeric 0..K or categorical), 0/undefined = unlabeled
%     classNames : 1-by-K cellstr, e.g. {'Sky','Building','Pole','Road',
%                  'Pavement','Tree','SignSymbol','Fence','Car',
%                  'Pedestrian','Bicyclist'}
%     cmap       : K-by-3 colors in [0,1], row k is the color of class k
%
%   L may be smaller/larger than img (network input size); the GUI resizes
%   the input for the overlay. If Python is used, wrap the py.* call here so
%   the GUI only ever sees this one MATLAB function.
    error('segmentSemantic:notImplemented', ...
        'Model semantic segmentation belum tersedia (bagian Person 2).');
end
