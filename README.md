# Image Segmentation

Tugas 3 IF4073 Pemrosesan Citra Digital: segmentasi citra dengan tiga pendekatan
yang disatukan dalam satu GUI MATLAB:

1. **Segmentasi berbasis deteksi tepi** (Laplace, LoG, Sobel, Prewitt, Roberts, Canny)
2. **Segmentasi klasik split and merge** (quadtree, divide and conquer)
3. **Segmentasi semantik dengan deep learning** (DeepLabV3+ ResNet-18, fine-tuning pada CamVid, 11 kelas)

Bagian B dan C diimplementasikan di MATLAB. Bagian D dilatih dengan PyTorch dan
dipanggil dari GUI MATLAB melalui integrasi Python (`pyenv`).

## Dependencies

| Requirement | Version | Used by | Notes |
|---|---|---|---|
| MATLAB | R2019b or later (tested on R2026a) | all | `uifigure`, `uigridlayout`, `uiaxes`, `pyenv` |
| Image Processing Toolbox | required | Parts B, C | `edge` (Canny only), morphology (`imclose`, `imfill`, `bwlabel`) |
| Python | 3.12 (from [python.org](https://www.python.org/downloads/)) | Part D | must be a version your MATLAB release supports |
| `torch`, `torchvision` | CPU build is enough (tested: 2.15.0) | Part D | no GPU needed for inference |
| `segmentation-models-pytorch` | 0.6.0 | Part D | same version as used for training |
| Trained weights `best_model.zip` | ~49 MB | Part D | not in git, see [Setup step 3](#setup) |

Deep Learning Toolbox is **not** needed: the CNN runs in Python.

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/nafannn/image-segmentation.git
   cd image-segmentation
   ```

2. **Install Python and the Part D libraries** (only needed for the Semantic tab)

   Install Python 3.12 from python.org. Avoid the Microsoft Store version, since
   MATLAB does not work reliably with it. Then install the libraries into *that*
   Python (use its full path if `python` points to a different install):
   ```bash
   python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
   python -m pip install segmentation-models-pytorch==0.6.0
   ```

3. **Download the trained weights**

   Download `best_model.zip` from the
   [Releases page](https://github.com/nafannn/image-segmentation/releases) and put it in
   `notebooks/output/`, next to `config.json`. Do not unzip it: a PyTorch checkpoint
   is itself a zip archive and is loaded as is (renaming it to `best_model.pth` also works).

4. **Point MATLAB to that Python** (once; MATLAB remembers it)
   ```matlab
   pyenv('Version', 'C:\Users\<you>\AppData\Local\Programs\Python\Python312\python.exe')
   ```
   Alternatively set the environment variable `SEG_PYTHON` to the interpreter path.
   `segmentSemantic.m` starts Python as a separate process (`ExecutionMode = OutOfProcess`)
   so PyTorch's native libraries do not clash with MATLAB's.

## How to Run

1. Open MATLAB and set the working directory to `src/`:
   ```matlab
   cd('path/to/image-segmentation/src')
   ```
2. Run the application:
   ```matlab
   SegmentationApp
   ```
3. Choose a tab (Edge Detection, Split & Merge, Semantic (CNN)), load an image from
   the dataset list or with **Browse**, then press **Run**.

On the Semantic tab the first **Run** takes about 15 s (starting Python and loading the
model); after that each image takes about 0.3–0.5 s on a CPU.

## Part D: Semantic Segmentation (CNN)

### Model

**DeepLabV3+** with a **ResNet-18** encoder pretrained on ImageNet
([segmentation-models-pytorch](https://github.com/qubvel-org/segmentation_models.pytorch)).
The pretrained encoder is fine-tuned together with a new decoder and an 11-class head
(transfer learning).

### Dataset: CamVid

CamVid (701 labeled frames, 720×960) is not stored in this repository because of its size.

- Images: http://web4.cs.ucl.ac.uk/staff/g.brostow/MotionSegRecData/files/701_StillsRaw_full.zip
- Pixel labels: http://web4.cs.ucl.ac.uk/staff/g.brostow/MotionSegRecData/data/LabeledApproved_full.zip

Training used the Kaggle version of CamVid, which contains the same frames with
`class_dict.csv` and the standard `train/val/test` split. To use it locally, extract it to
`data/CamVid/` (ignored by git).

**Split:** 369 train / 100 validation / 232 test. This is the standard CamVid split, which
separates frames by video sequence, so near-identical neighboring frames never appear in
both training and test data.

**Class grouping (32 → 11):**

| Class | Original CamVid classes |
|---|---|
| Sky | Sky |
| Building | Building, Wall, Bridge, Tunnel, Archway |
| Pole | Column_Pole, TrafficCone |
| Road | Road, LaneMkgsDriv, LaneMkgsNonDriv |
| Pavement | Sidewalk, ParkingBlock, RoadShoulder |
| Tree | Tree, VegetationMisc |
| SignSymbol | SignSymbol, Misc_Text, TrafficLight |
| Fence | Fence |
| Car | Car, SUVPickupTruck, Truck_Bus, Train, OtherMoving |
| Pedestrian | Pedestrian, Child, CartLuggagePram, Animal |
| Bicyclist | Bicyclist, MotorcycleScooter |
| *(ignored)* | Void |

### Training

Notebook: [`notebooks/tugas-3-pengolahan-citra-digital.ipynb`](notebooks/tugas-3-pengolahan-citra-digital.ipynb),
run on Kaggle (GPU T4).

| Setting | Value |
|---|---|
| Input size | 384×512 (CamVid downscaled, same 3:4 aspect ratio) |
| Augmentation | random scale 0.75–1.25, random crop, horizontal flip |
| Loss | pixel-wise cross-entropy, median-frequency class weights, Void ignored |
| Optimizer | AdamW, LR 1e-4 (encoder) / 1e-3 (decoder + head), weight decay 1e-4 |
| LR schedule | polynomial decay (power 0.9) |
| Epochs / batch | 80 / 8, best checkpoint chosen by validation mIoU |

All settings are also stored in [`notebooks/output/config.json`](notebooks/output/config.json).

**To retrain:** upload the notebook to Kaggle, add the CamVid dataset as input, enable
GPU and Internet, then **Save & Run All**. Download `best_model.pth` (it may arrive
as `best_model.zip`) and `config.json` into `notebooks/output/`.

### Results (CamVid test set, 232 images, full 720×960 resolution)

| Metric | Value |
|---|---|
| Global pixel accuracy | 0.912 |
| Mean class accuracy | 0.837 |
| Mean IoU | 0.679 |

| Class | IoU | Class | IoU |
|---|---|---|---|
| Sky | 0.919 | SignSymbol | 0.466 |
| Building | 0.840 | Fence | 0.551 |
| Pole | 0.276 | Car | 0.817 |
| Road | 0.940 | Pedestrian | 0.501 |
| Pavement | 0.773 | Bicyclist | 0.595 |
| Tree | 0.789 | | |

Figures (confusion matrix, sample predictions, training curves) are in `notebooks/output/`.

### How the GUI calls the model

`SegmentationApp` → `segmentSemantic(img)` (MATLAB) → `semantic_predict.predict()` (Python):
the image is resized to 384×512 and normalized, the network predicts class scores, the scores
are upsampled back to the original size, and the most likely class is taken per pixel.
`segmentSemantic` returns the label image (1–11), the class names and the class colors.

## File Structure

- `src/`: MATLAB source code
  - `SegmentationApp.m`: main GUI
  - `core/`: shared utilities (convolution, thresholding, display helpers, registries)
  - `b-edge-detection/`: Part B, edge operators and edge-based object segmentation
  - `c-split-merge/`: Part C, quadtree split and merge
  - `d-semantic/`: Part D, semantic segmentation
    - `segmentSemantic.m`: MATLAB entry point used by the GUI
    - `semantic_predict.py`: PyTorch inference (model loading, preprocessing, prediction)
- `notebooks/`: Kaggle training notebook
  - `output/`: training outputs (`config.json`, metrics, figures; weights downloaded separately)
- `scripts/`: batch experiments and helper scripts
  - `prepareCamVid.m`: converts CamVid RGB labels into 11-class index masks (local evaluation)
- `data/`: test images (see [data/README.md](data/README.md))
- `results/`: experiment outputs used in the report

## License

[MIT License](LICENSE)
