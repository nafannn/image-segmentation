function registry = splitMergeRegistry()
%SPLITMERGEREGISTRY Predikat homogenitas/parameter untuk tab Split and
%   Merge (Bagian C). Intensitas memakai skala gray 0-255.
%   Default dituning pada 8 citra BSDS500 (481x321) supaya hasil di GUI
%   langsung masuk akal: minBlock 16 px dan minRegion 1500 px mencegah
%   ribuan blok/region kecil, sedangkan Tsplit/Tmerge 25 (std) atau 60 (range)
%   memberi puluhan region, bukan ratusan. Threshold tetap bisa diubah per
%   citra dari GUI atau dari script (parameter diizinkan disesuaikan).
    registry = struct('Key', {}, 'Label', {}, 'Params', {});

    registry(end+1) = entry('range', 'Range: max - min <= T', { ...
        param('Tsplit',    'Split threshold T',       60, 1, 255, 1), ...
        param('minBlock',  'Min block size (px)',     16, 1, 128, 1), ...
        param('Tmerge',    'Merge threshold',         60, 0, 255, 1), ...
        param('minRegion', 'Min region area (px)',  1500, 0, 100000, 10)});

    registry(end+1) = entry('std', 'Std deviation <= T', { ...
        param('Tsplit',    'Split threshold T',       25, 0.5, 128, 0.5), ...
        param('minBlock',  'Min block size (px)',     16, 1, 128, 1), ...
        param('Tmerge',    'Merge threshold',         25, 0, 128, 0.5), ...
        param('minRegion', 'Min region area (px)',  1500, 0, 100000, 10)});
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
