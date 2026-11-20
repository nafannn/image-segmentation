"""Part D inference: DeepLabV3+ (ResNet-18) fine-tuned on CamVid, 11 classes.

Called from MATLAB by segmentSemantic.m:
    pred = py.semantic_predict.predict(py.numpy.asarray(img), modelDir)

The model is loaded once and kept in memory, so only the first call is slow.
The preprocessing here must match training (notebooks/kaggle_train_camvid.md):
resize to 384x512, ImageNet normalization, then upsample the class scores
back to the input size before taking argmax.

Can also be run from the command line for a quick test:
    python semantic_predict.py <image> <model_dir> [out.png]
"""
import json
import os

import numpy as np
import torch
import torch.nn.functional as F
import segmentation_models_pytorch as smp

_MODEL = None       # cached network (loaded on the first predict call)
_CFG = None         # cached config.json
_MODEL_DIR = None   # which folder the cached model came from


def _load(model_dir):
    """Rebuild the network from config.json and load the fine-tuned weights."""
    global _MODEL, _CFG, _MODEL_DIR
    with open(os.path.join(model_dir, 'config.json'), encoding='utf-8') as f:
        cfg = json.load(f)
    # encoder_weights=None: the ImageNet weights are not needed here, every
    # weight (encoder included) is overwritten by the fine-tuned state_dict.
    model = smp.DeepLabV3Plus(encoder_name=cfg['encoder'], encoder_weights=None,
                              classes=len(cfg['class_names']))
    # Kaggle may download the checkpoint as .zip: a .pth file IS a zip
    # archive, so torch.load reads either name.
    for name in ('best_model.pth', 'best_model.zip'):
        weights = os.path.join(model_dir, name)
        if os.path.isfile(weights):
            break
    else:
        raise FileNotFoundError(f'best_model.pth / best_model.zip not found in {model_dir}')
    state = torch.load(weights, map_location='cpu', weights_only=True)
    model.load_state_dict(state)
    model.eval()   # BatchNorm uses its stored statistics, no dropout
    _MODEL, _CFG, _MODEL_DIR = model, cfg, model_dir


@torch.no_grad()
def predict(img, model_dir):
    """RGB image (H,W,3) uint8 -> class-index map (H,W) uint8, values 0..10."""
    if _MODEL is None or _MODEL_DIR != str(model_dir):
        _load(str(model_dir))
    cfg = _CFG

    rgb = np.asarray(img, dtype=np.uint8)
    if rgb.ndim == 2:                       # grayscale -> 3 identical channels
        rgb = np.stack([rgb] * 3, axis=-1)
    rgb = rgb[..., :3]                      # drop alpha if present
    h, w = rgb.shape[:2]

    # HWC uint8 -> 1x3xHxW float in [0,1]
    x = torch.from_numpy(np.ascontiguousarray(rgb)).permute(2, 0, 1)[None].float() / 255.0
    # Resize to the training resolution (antialias ~ area downsampling used in training)
    x = F.interpolate(x, size=(cfg['in_h'], cfg['in_w']), mode='bilinear',
                      align_corners=False, antialias=True)
    # ImageNet normalization (same mean/std as training)
    mean = torch.tensor(cfg['mean']).view(1, 3, 1, 1)
    std = torch.tensor(cfg['std']).view(1, 3, 1, 1)
    x = (x - mean) / std

    logits = _MODEL(x)                      # 1 x K x 384 x 512 class scores
    # Upsample the scores (not the labels) to the original size, then pick the
    # most likely class per pixel -> smoother boundaries than resizing labels.
    logits = F.interpolate(logits, size=(h, w), mode='bilinear', align_corners=False)
    return logits.argmax(1)[0].numpy().astype(np.uint8)


if __name__ == '__main__':
    import sys
    import time
    from PIL import Image

    image_path, model_dir = sys.argv[1], sys.argv[2]
    img = np.array(Image.open(image_path).convert('RGB'))
    t0 = time.time()
    pred = predict(img, model_dir)
    print(f'{image_path}: {pred.shape}, classes present {np.unique(pred).tolist()}, '
          f'{time.time() - t0:.2f}s (incl. model load)')
    if len(sys.argv) > 3:
        cmap = np.array(_CFG['cmap'], np.uint8)
        Image.fromarray(cmap[pred]).save(sys.argv[3])
        print('saved', sys.argv[3])
