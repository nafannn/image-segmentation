%TEST_BASIC Sanity test for Part B on a synthetic image with known edges.
%   Run from the repository root or from scripts/:
%       run('scripts/test_basic.m')
%   A bright disk on a dark background (plus light noise) is passed to every
%   operator. Checks:
%     1) myConv2 matches conv2 (when the toolbox-free reference is available)
%     2) edges lie near the true circle boundary (precision) and cover it (recall)
%     3) the object mask overlaps the true disk (IoU)
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, '..', 'src')));

% ---- synthetic image: disk radius 40 in a 128x128 image ----
rng(4073);
[X, Y] = meshgrid(1:128, 1:128);
truth = (X - 64).^2 + (Y - 64).^2 <= 40^2;
img = uint8(60 + 140 * truth + 4 * randn(128));
boundary = truth & ~imerode(truth, strel('disk', 1));
nearBoundary = imdilate(boundary, strel('disk', 3));     % tolerance band of 3 px

% ---- 1) convolution check (interior only: borders differ by padding mode) ----
K = [1 2 1; 0 0 0; -1 -2 -1];
ref = conv2(double(img), K, 'same');
own = myConv2(img, K);
convErr = max(max(abs(ref(3:end-2, 3:end-2) - own(3:end-2, 3:end-2))));
fprintf('myConv2 vs conv2 max interior error: %.2e\n', convErr);
assert(convErr < 1e-9, 'myConv2 does not match conv2');

% ---- 2) + 3) every operator ----
[reg, segSpecs] = edgeRegistry();
seg = struct();
for s = segSpecs
    seg.(s.Name) = s.Default;
end
thr = struct('Mode', 'otsu', 'Value', 0);
fprintf('%-28s %9s %9s %9s\n', 'Operator', 'Precision', 'Recall', 'Mask IoU');
allOk = true;
for k = 1:numel(reg)
    p = struct();
    for s = reg(k).Params
        p.(s.Name) = s.Default;
    end
    [R, ~] = applyEdgeSegmentation(img, reg(k).Key, p, thr, seg);
    E = R.Edges;
    precision = nnz(E & nearBoundary) / max(nnz(E), 1);
    recall = nnz(imdilate(E, strel('disk', 3)) & boundary) / nnz(boundary);
    iou = nnz(R.Mask & truth) / nnz(R.Mask | truth);
    ok = precision > 0.8 && recall > 0.8 && iou > 0.9;
    allOk = allOk && ok;
    fprintf('%-28s %9.3f %9.3f %9.3f  %s\n', reg(k).Label, precision, recall, iou, ...
        string(ok));
end
assert(allOk, 'At least one operator failed the synthetic test');
disp('test_basic: ALL PASSED');
