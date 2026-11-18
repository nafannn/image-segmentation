function registry = splitMergeRegistry()
%SPLITMERGEREGISTRY Homogeneity predicates/parameters for the Split and
%   Merge tab (Part C). Intensities are on the 0-255 gray scale, so the
%   thresholds match the "within threshold" examples in the lecture.
    registry = struct('Key', {}, 'Label', {}, 'Params', {});

    registry(end+1) = entry('range', 'Range: max - min <= T', { ...
        param('Tsplit',    'Split threshold T',       40, 1, 255, 1), ...
        param('minBlock',  'Min block size (px)',      4, 1, 128, 1), ...
        param('Tmerge',    'Merge threshold',         40, 0, 255, 1), ...
        param('minRegion', 'Min region area (px)',     0, 0, 100000, 10)});

    registry(end+1) = entry('std', 'Std deviation <= T', { ...
        param('Tsplit',    'Split threshold T',       12, 0.5, 128, 0.5), ...
        param('minBlock',  'Min block size (px)',      4, 1, 128, 1), ...
        param('Tmerge',    'Merge threshold',         12, 0, 128, 0.5), ...
        param('minRegion', 'Min region area (px)',     0, 0, 100000, 10)});
end

function e = entry(key, label, params)
    e.Key = key;
    e.Label = label;
    e.Params = [params{:}];
end

function p = param(name, label, default, minVal, maxVal, step)
    p.Name = name;
    p.Label = label;
    p.Default = default;
    p.Min = minVal;
    p.Max = maxVal;
    p.Step = step;
end
