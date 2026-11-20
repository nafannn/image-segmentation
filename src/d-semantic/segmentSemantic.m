function [L, classNames, cmap] = segmentSemantic(img)
%SEGMENTSEMANTIC Part D entry point called by the GUI (Semantic tab).
%   [L, classNames, cmap] = segmentSemantic(img)
%
%   Runs DeepLabV3+ (ResNet-18 encoder, ImageNet-pretrained, fine-tuned on
%   CamVid with 11 classes) through Python/PyTorch. The network itself lives
%   in semantic_predict.py; this function only bridges MATLAB <-> Python so
%   the GUI never touches py.* directly.
%
%   img        : H-by-W-by-3 RGB image (uint8, or anything im2uint8 accepts)
%   L          : H-by-W double label image, 1..11 = class (0 = unlabeled,
%                never produced here because every pixel gets a class)
%   classNames : 1-by-11 cellstr {'Sky','Building',...,'Bicyclist'}
%   cmap       : 11-by-3 class colors in [0,1]
%
%   Requirements (see README):
%     - notebooks/output/best_model.zip (or .pth) and notebooks/output/config.json
%     - a Python with torch + segmentation-models-pytorch, selected once with
%         pyenv('Version', 'C:\path\to\python.exe')
%       or through the environment variable SEG_PYTHON.

    here = fileparts(mfilename('fullpath'));        % src/d-semantic
    modelDir = fullfile(fileparts(fileparts(here)), 'notebooks', 'output');
    cfgFile = fullfile(modelDir, 'config.json');
    hasWeights = isfile(fullfile(modelDir, 'best_model.pth')) || ...
                 isfile(fullfile(modelDir, 'best_model.zip'));   % Kaggle download name
    if ~hasWeights || ~isfile(cfgFile)
        error('segmentSemantic:noModel', ...
            'Model tidak ditemukan. Letakkan best_model.zip (atau .pth) dan config.json di:\n%s', modelDir);
    end

    setupPython();

    % Make semantic_predict.py importable (only added once).
    if count(py.sys.path, here) == 0
        insert(py.sys.path, int32(0), here);
    end
    mod = py.importlib.import_module('semantic_predict');

    % The network expects 3-channel uint8 RGB (converted by hand so this
    % part does not depend on the Image Processing Toolbox).
    if isfloat(img)
        img = uint8(255 * min(max(img, 0), 1));   % [0,1] double/single
    elseif islogical(img)
        img = uint8(img) * 255;
    elseif isa(img, 'uint16')
        img = uint8(double(img) / 257);           % 0..65535 -> 0..255
    end
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end

    % MATLAB array -> numpy, run the model, numpy -> MATLAB.
    % The model is cached inside the Python process, so only the first
    % call pays for loading the weights.
    pred = mod.predict(py.numpy.asarray(img), modelDir);
    L = double(uint8(pred)) + 1;     % Python classes 0..10 -> GUI labels 1..11

    % Class names and colors come from the same config used in training,
    % so the legend always matches the model.
    cfg = jsondecode(fileread(cfgFile));
    classNames = reshape(cellstr(cfg.class_names), 1, []);
    cmap = double(cfg.cmap) / 255;
end

function setupPython()
%SETUPPYTHON Select the Python interpreter the first time it is needed.
%   OutOfProcess runs Python as a separate process: PyTorch's native
%   libraries (MKL/OpenMP) can clash with MATLAB's own copies in-process.
    pe = pyenv;
    if pe.Status ~= "NotLoaded"
        return;                                      % already running
    end
    exe = getenv('SEG_PYTHON');
    if ~isempty(exe)
        pyenv('Version', exe, 'ExecutionMode', 'OutOfProcess');
    elseif strlength(pe.Version) > 0
        pyenv('Version', pe.Executable, 'ExecutionMode', 'OutOfProcess');
    else
        error('segmentSemantic:noPython', ...
            ['Python belum dikonfigurasi. Jalankan sekali:\n' ...
             '  pyenv(''Version'', ''C:\\path\\to\\python.exe'')\n' ...
             'dengan Python yang sudah ter-install torch dan segmentation-models-pytorch.']);
    end
end
