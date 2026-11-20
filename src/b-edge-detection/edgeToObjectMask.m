function [mask, info] = edgeToObjectMask(E, closeRadius, minArea, keepN, clearBorder)
%EDGETOOBJECTMASK Build an object mask from a binary edge map.
%   [mask, info] = edgeToObjectMask(E, closeRadius, minArea, keepN, clearBorder)
%     E           : logical edge map
%     closeRadius : radius (px) of the disk used to bridge gaps in edges
%     minArea     : regions smaller than this (px) are discarded as noise
%     keepN       : number of largest regions kept as "main objects"
%     clearBorder : true -> discard regions touching the image border
%                   (dense texture / background usually does, objects often not)
%
%   Idea (object shape from its edges): an object's outline is a closed
%   curve. Once the curve is closed, its interior can be filled, which
%   separates the object from the background.
%     1. Closing (dilate then erode) connects broken edge segments so the
%        outline becomes a closed curve.
%     2. Hole filling turns every closed curve into a solid region.
%     3. Opening removes leftover thin edge lines that enclose nothing
%        (texture, isolated edges) while keeping solid regions.
%     4. Optionally drop regions touching the border, drop small regions,
%        and keep only the keepN largest.
    if nargin < 5
        clearBorder = false;
    end
    E = logical(E);
    info = struct('NumCandidates', 0, 'KeptAreas', []);

    % 1) Close gaps along the outline
    if closeRadius > 0
        se = strel('disk', round(closeRadius), 0);
        closed = imclose(E, se);
    else
        closed = E;
    end

    % 2) Fill the interior of every closed contour
    filled = imfill(closed, 'holes');

    % 3) Opening with the same disk removes lines thinner than the disk
    if closeRadius > 0
        filled = imopen(filled, se);
    end

    % 4) Drop border blobs and small blobs, then keep the N largest components
    if clearBorder
        filled = dropBorderRegions(filled, 5);
    end
    if minArea > 0
        filled = bwareaopen(filled, round(minArea));
    end
    [lbl, n] = bwlabel(filled, 8);
    info.NumCandidates = n;
    mask = false(size(E));
    if n == 0
        return;
    end
    areas = accumarray(lbl(lbl > 0), 1, [n 1]);     % pixel count per region
    [areas, order] = sort(areas, 'descend');
    keep = order(1:min(round(keepN), n));
    mask = ismember(lbl, keep);
    info.KeptAreas = areas(1:numel(keep))';
end

function bw = dropBorderRegions(bw, margin)
% Remove every connected region that has a pixel within `margin` px of the
% image border. A margin (instead of exactly touching) is needed because some
% detectors, e.g. Canny, never mark the outermost pixels as edges.
    [lbl, n] = bwlabel(bw, 8);
    if n == 0
        return;
    end
    band = true(size(bw));
    band(margin + 1:end - margin, margin + 1:end - margin) = false;   % frame of width margin
    touching = unique(lbl(band & lbl > 0));
    bw(ismember(lbl, touching)) = false;
end
