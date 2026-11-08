# Image Segmentation

Tugas 3 IF4073 Pemrosesan Citra Digital: segmentasi citra dengan tiga pendekatan
yang disatukan dalam satu GUI MATLAB:

1. **Segmentasi berbasis deteksi tepi** (Laplace, LoG, Sobel, Prewitt, Roberts, Canny)
2. **Segmentasi klasik split and merge** (quadtree, divide and conquer)
3. **Segmentasi semantik dengan deep learning** (pretrained CNN, fine-tuning pada CamVid)

> README ini masih kerangka dan akan dilengkapi seiring pengerjaan.

## Dependencies

| Requirement | Version | Notes |
|---|---|---|
| MATLAB | R2019b or later | `uifigure`, `uigridlayout`, `uiaxes` |
| Image Processing Toolbox | Required | `edge` (Canny only), morphology (`imclose`, `imfill`, `bwlabel`) |

## How to Run

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd image-segmentation
   ```
2. Open MATLAB and set the working directory to `src/`:
   ```matlab
   cd('path/to/image-segmentation/src')
   ```
3. Run the application:
   ```matlab
   SegmentationApp
   ```

## File Structure

- `src/`: MATLAB source code
  - `SegmentationApp.m`: main GUI
  - `core/`: shared utilities (convolution, thresholding, display helpers, registries)
  - `b-edge-detection/`: Part B, edge operators and edge-based object segmentation
  - `c-split-merge/`: Part C, quadtree split and merge
  - `d-semantic/`: Part D, semantic segmentation (CNN)
- `scripts/`: batch experiments and sanity tests
- `data/`: test images (see [data/README.md](data/README.md))
- `results/`: experiment outputs used in the report

## License

[MIT License](LICENSE)
