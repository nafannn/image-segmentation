function [registry, segSpecs] = edgeRegistry()
%EDGEREGISTRY Operator/parameter untuk tab Edge Detection (Bagian B).
%   registry : struct array, satu entri per operator tepi. GUI membangun
%              dropdown dan panel parameternya dari daftar ini.
%   segSpecs : spesifikasi parameter untuk post-processing tepi -> mask objek
%              (dipakai bersama oleh semua operator).
%   Tambah operator di sini, dia langsung muncul di app tanpa mengubah GUI.
    registry = struct('Key', {}, 'Label', {}, 'UsesThreshold', {}, 'Params', {});

    % Operator orde satu (gradien) -> magnitude, lalu di-threshold.
    % `mag` memilih varian kekuatan tepi: 1 = sqrt(Gx^2+Gy^2) (eksak),
    % 2 = |Gx|+|Gy|, 3 = max(|Gx|,|Gy|) (aproksimasi yang lebih murah).
    registry(end+1) = entry('roberts', 'Roberts (cross 2x2)', true, { ...
        param('mag', 'Magnitude (1=akar, 2=jumlah, 3=max)', 1, 1, 3, 1)});
    registry(end+1) = entry('prewitt', 'Prewitt (3x3, c = 1)', true, { ...
        param('mag', 'Magnitude (1=akar, 2=jumlah, 3=max)', 1, 1, 3, 1)});
    registry(end+1) = entry('sobel',   'Sobel (3x3, c = 2)',   true, { ...
        param('mag', 'Magnitude (1=akar, 2=jumlah, 3=max)', 1, 1, 3, 1)});

    % Operator orde dua -> zero-crossing, di-threshold pada kekuatan slope
    registry(end+1) = entry('laplace', 'Laplace (zero-crossing)', true, { ...
        param('neighbors', 'Neighborhood (4 or 8)', 8, 4, 8, 4)});
    registry(end+1) = entry('log', 'Laplacian of Gaussian (LoG)', true, { ...
        param('sigma', 'Sigma', 2, 0.5, 10, 0.1)});

    % Canny: built-in MATLAB boleh dipakai sesuai soal
    registry(end+1) = entry('canny', 'Canny (built-in)', false, { ...
        param('low',   'Low threshold (T1)',  0.05, 0.001, 0.99, 0.01), ...
        param('high',  'High threshold (T2)', 0.15, 0.002, 1.00, 0.01), ...
        param('sigma', 'Sigma', sqrt(2), 0.5, 10, 0.1)});

    % Pre-processing + peta tepi -> mask objek: closing, isi lubang, lalu
    % simpan region utama saja
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
