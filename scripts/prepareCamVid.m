%PREPARECAMVID Convert CamVid RGB label images (32 classes) into 11-class index masks.
%   CamVid labels are color-coded PNGs: each of the 32 original classes has
%   a unique RGB color (see data/CamVid/class_dict.csv). This script groups
%   them into the 11 classes required by the assignment and writes one
%   single-channel PNG per frame:
%       pixel value 0..10 -> class index (order of CLASS_NAMES below)
%       pixel value 255   -> Void / unlabeled (ignored in training & metrics)
%
%   Input : data/CamVid/{train,val,test}_labels/*_L.png
%   Output: data/CamVid/{train,val,test}_labels11/*.png  (same base name as the image)
%
%   Run from the repo root:  run('scripts/prepareCamVid.m')

camvidDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'CamVid');

% The 11 target classes (index 0..10 in the output masks).
CLASS_NAMES = {'Sky','Building','Pole','Road','Pavement','Tree', ...
               'SignSymbol','Fence','Car','Pedestrian','Bicyclist'};

% Grouping of the 31 non-void CamVid colors into the 11 classes.
% Same grouping as the MathWorks CamVid example (camvidPixelLabelIDs).
groups = {
    % Sky
    [128 128 128]                                   % Sky
    % Building
    [000 128 064; 128 000 000; 064 192 000; ...     % Bridge, Building, Wall
     064 000 064; 192 000 128]                      % Tunnel, Archway
    % Pole
    [192 192 128; 000 000 064]                      % Column_Pole, TrafficCone
    % Road
    [128 064 128; 128 000 192; 192 000 064]         % Road, LaneMkgsDriv, LaneMkgsNonDriv
    % Pavement
    [000 000 192; 064 192 128; 128 128 192]         % Sidewalk, ParkingBlock, RoadShoulder
    % Tree
    [128 128 000; 192 192 000]                      % Tree, VegetationMisc
    % SignSymbol
    [192 128 128; 128 128 064; 000 064 064]         % SignSymbol, Misc_Text, TrafficLight
    % Fence
    [064 064 128]                                   % Fence
    % Car
    [064 000 128; 064 128 192; 192 128 192; ...     % Car, SUVPickupTruck, Truck_Bus
     192 064 128; 128 064 064]                      % Train, OtherMoving
    % Pedestrian
    [064 064 000; 192 128 064; 064 000 192; ...     % Pedestrian, Child, CartLuggagePram
     064 128 064]                                   % Animal
    % Bicyclist
    [000 128 192; 192 000 192]                      % Bicyclist, MotorcycleScooter
};

% Build a lookup table indexed by the packed RGB value R*65536 + G*256 + B.
% Every color starts as 255 (void); only the 31 known colors get a class.
% A 2^24 uint8 table is 16 MB, and turns the per-pixel mapping into one
% vectorized index operation instead of 31 color comparisons.
lut = repmat(uint8(255), 2^24, 1);
for k = 1:numel(groups)
    rgb = groups{k};
    keys = rgb(:,1)*65536 + rgb(:,2)*256 + rgb(:,3);
    lut(keys + 1) = uint8(k - 1);                   % +1: MATLAB is 1-based
end

splits = {'train','val','test'};
pixelCount = zeros(1, numel(CLASS_NAMES) + 1);      % last bin = void
for s = 1:numel(splits)
    inDir  = fullfile(camvidDir, [splits{s} '_labels']);
    outDir = fullfile(camvidDir, [splits{s} '_labels11']);
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    files = dir(fullfile(inDir, '*_L.png'));
    for i = 1:numel(files)
        rgb = uint32(imread(fullfile(inDir, files(i).name)));
        key = rgb(:,:,1)*65536 + rgb(:,:,2)*256 + rgb(:,:,3);
        mask = lut(key + 1);                        % H-by-W uint8, 0..10 or 255

        % Accumulate class statistics (useful for class weighting later).
        counts = histcounts(mask, [-0.5:1:10.5, 255.5]);
        pixelCount = pixelCount + counts;

        % Save with the same base name as the RGB frame (drop the "_L" suffix)
        % so image i and mask i can be matched by file name.
        outName = strrep(files(i).name, '_L.png', '.png');
        imwrite(mask, fullfile(outDir, outName));
    end
    fprintf('%-5s: %d masks written to %s\n', splits{s}, numel(files), outDir);
end

% Report class distribution: CamVid is heavily imbalanced (Road/Sky/Building
% dominate), which is why class weights are needed during training.
fprintf('\nPixel share per class:\n');
total = sum(pixelCount);
names = [CLASS_NAMES, {'Void'}];
for k = 1:numel(names)
    fprintf('  %-11s %6.2f%%\n', names{k}, 100 * pixelCount(k) / total);
end
