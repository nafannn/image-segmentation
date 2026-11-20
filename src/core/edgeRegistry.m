function [registry, segSpecs] = edgeRegistry()
%EDGEREGISTRY Operators/parameters for the Edge Detection tab (Part B).
%   registry : struct array, one entry per edge operator. The GUI builds
%              its dropdown and parameter panel from this list.
%   segSpecs : parameter specs for the edge -> object mask post-processing
%              (shared by every operator).
%   Add an operator here and it appears in the app with no other GUI change.
    registry = struct('Key', {}, 'Label', {}, 'UsesThreshold', {}, 'Params', {});

    % First-order (gradient) operators -> magnitude, then thresholded
    registry(end+1) = entry('roberts', 'Roberts (cross 2x2)', true, {});
    registry(end+1) = entry('prewitt', 'Prewitt (3x3, c = 1)', true, {});
    registry(end+1) = entry('sobel',   'Sobel (3x3, c = 2)',   true, {});

    % Second-order operators -> zero-crossing, threshold on slope strength
    registry(end+1) = entry('laplace', 'Laplace (zero-crossing)', true, { ...
        param('neighbors', 'Neighborhood (4 or 8)', 8, 4, 8, 4)});
    registry(end+1) = entry('log', 'Laplacian of Gaussian (LoG)', true, { ...
        param('sigma', 'Sigma', 2, 0.5, 10, 0.1)});

    % Canny: MATLAB built-in is allowed by the assignment
    registry(end+1) = entry('canny', 'Canny (built-in)', false, { ...
        param('low',   'Low threshold (T1)',  0.05, 0.001, 0.99, 0.01), ...
        param('high',  'High threshold (T2)', 0.15, 0.002, 1.00, 0.01), ...
        param('sigma', 'Sigma', sqrt(2), 0.5, 10, 0.1)});

    % Pre-processing + edge map -> object mask (closing, hole filling, keep main regions)
    segSpecs = paramList({ ...
        param('preSigma',    'Pre-smoothing sigma (0 = off)', 0, 0, 10, 0.1), ...
        param('closeRadius', 'Closing radius (px)', 3, 0, 30, 1), ...
        param('minArea',     'Min region area (px)', 200, 0, 100000, 10), ...
        param('keepN',       'Regions to keep', 1, 1, 20, 1), ...
        param('clearBorder', 'Drop border regions (0/1)', 1, 0, 1, 1)});
end

function e = entry(key, label, usesThreshold, params)
    e.Key = key;
    e.Label = label;
    e.UsesThreshold = usesThreshold;
    e.Params = paramList(params);
end

function list = paramList(params)
    if isempty(params)
        list = struct('Name', {}, 'Label', {}, 'Default', {}, 'Min', {}, 'Max', {}, 'Step', {});
    else
        list = [params{:}];
    end
end

function p = param(name, label, default, minVal, maxVal, step)
    p.Name = name;
    p.Label = label;
    p.Default = default;
    p.Min = minVal;
    p.Max = maxVal;
    p.Step = step;
end
