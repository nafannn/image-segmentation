# Image Segmentation Studio

Program GUI MATLAB untuk Tugas 3 IF4073 Pemrosesan Citra Digital. Satu aplikasi
menyatukan tiga pendekatan segmentasi citra, masing-masing dalam satu tab:

| Tab | Bagian | Isi |
|---|---|---|
| **Edge Detection** | B | Segmentasi objek dari hasil deteksi tepi: Laplace, LoG, Sobel, Prewitt, Roberts (ditulis sendiri) dan Canny (bawaan MATLAB, memang diizinkan soal) |
| **Split & Merge** | C | Segmentasi klasik divide and conquer: quadtree split dengan predikat homogenitas `range` atau `std`, lalu merge region bertetangga yang gabungannya masih homogen |
| **Semantic (CNN)** | D | Segmentasi semantik dengan DeepLabV3+ (encoder ResNet-18 pretrained ImageNet) yang di-fine-tune pada CamVid (11 kelas); model dilatih dengan PyTorch dan dipanggil dari GUI MATLAB lewat `pyenv` |

Anggota kelompok:

| Nama | NIM |
|---|---|
| Nurul Na'im Natifah | 18223106 |
| Muhammad Izzat Jundy | 13523094 |

![Tampilan tab Edge Detection](docs/gui_preview.jpg)

*Tangkapan layar tab Edge Detection setelah menjalankan Sobel pada `101027.jpg`.
Status bar di bawah menampilkan parameter efektif, jumlah piksel tepi, jumlah
objek, dan waktu proses.*

## Dependensi

| Kebutuhan | Versi | Catatan |
|---|---|---|
| MATLAB | R2019b atau lebih baru | memakai `uifigure`, `uigridlayout`, `uiaxes`; diuji pada R2026a |
| Image Processing Toolbox | wajib | `strel`, `imclose`, `imfill`, `bwareaopen`, `bwlabel`, `imdilate`, `imerode`, dan `edge` (khusus operator Canny) |
| Computer Vision Toolbox | opsional | hanya untuk caption pada gambar panel; tanpa toolbox ini gambar tetap jadi, teks judulnya saja yang kosong |
| Python | 3.12 dari [python.org](https://www.python.org/downloads/) | hanya tab Semantic (bagian D); jangan pakai Python dari Microsoft Store karena tidak stabil dengan MATLAB |
| `torch`, `torchvision` | build CPU cukup (diuji 2.15.0) | inferensi model bagian D, tidak perlu GPU |
| `segmentation-models-pytorch` | 0.6.0 | arsitektur DeepLabV3+, versi sama dengan saat pelatihan |

Deep Learning Toolbox **tidak** diperlukan: CNN bagian D berjalan di Python dan
dipanggil dari MATLAB.

Operator deteksi tepi bagian B **tidak** memakai fungsi bawaan MATLAB:
konvolusi, Otsu, dan penelusuran zero-crossing ditulis sendiri di `src/core` dan
`src/b-edge-detection`. Toolbox hanya dipakai untuk morfologi (menutup celah
kontur, mengisi lubang, memberi label region).

## Cara Menjalankan

1. Clone repositori lalu masuk ke foldernya:
   ```bash
   git clone https://github.com/nafannn/image-segmentation.git
   cd image-segmentation
   ```
2. *(Hanya untuk tab Semantic)* Siapkan Python bagian D, cukup sekali:
   ```bash
   python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
   python -m pip install segmentation-models-pytorch==0.6.0
   ```
   Pakai path lengkap `python.exe` kalau perintah `python` menunjuk ke instalasi
   lain. Lalu di MATLAB, arahkan ke Python tersebut (MATLAB mengingatnya):
   ```matlab
   pyenv('Version', 'C:\Users\<nama>\AppData\Local\Programs\Python\Python312\python.exe')
   ```
   Alternatif: set environment variable `SEG_PYTHON` ke path interpreter tersebut.
   Bobot model (`notebooks/output/best_model.zip`) sudah ikut di repositori, jangan
   di-unzip: checkpoint PyTorch memang berformat zip dan dimuat apa adanya.
3. Buka MATLAB, lalu jalankan dari **root repo**:
   ```matlab
   addpath(genpath('src'))
   SegmentationApp
   ```
   Alternatif: `cd src` lalu `SegmentationApp` (aplikasi menambahkan foldernya
   sendiri ke path, tetapi `data/` dicari relatif terhadap root repo).
4. Jendela GUI terbuka dengan tiga tab. Di setiap tab:

   | Langkah | Keterangan |
   |---|---|
   | 1. Pilih citra | dropdown berisi 8 citra BSDS500 dari `data/bsds500/`, atau tombol **Browse...** untuk citra lain |
   | 2. Atur parameter | panel kiri; isinya menyesuaikan operator/predikat yang dipilih |
   | 3. **Run** | menjalankan pipeline; status bar menampilkan parameter efektif, jumlah objek/region, dan waktu proses |
   | 4. **Reset** | mengosongkan citra dan mengembalikan parameter ke nilai default |
   | 5. **Export View** | menyimpan seluruh tampilan jendela sebagai PNG |

5. Panel di sisi kanan menampilkan hasil bertahap:

   | Tab | Urutan panel |
   |---|---|
   | Edge Detection | citra asli, respons operator, peta tepi biner, mask objek, hasil segmentasi, kontur objek |
   | Split & Merge | citra asli, grid quadtree, rata-rata blok, rata-rata region, label region, batas region |
   | Semantic | citra masukan, label semantik, overlay, plus legenda kelas |

### Parameter yang sering disesuaikan

| Tab | Parameter | Arti |
|---|---|---|
| Edge Detection | `Otsu` / `Percentile` / `Manual` | cara memilih ambang peta tepi; Otsu otomatis dari histogram respons |
| | `Magnitude` (1/2/3) | varian kekuatan tepi: akar, jumlah absolut, atau maksimum |
| | `preSigma`, `closeRadius`, `minArea`, `keepN`, `clearBorder` | pra-pelebaran Gaussian, radius closing, luas region minimal, jumlah region yang dipertahankan, buang region yang menyentuh tepi |
| Split & Merge | `Tsplit` / `Tmerge` | threshold homogenitas saat split / saat merge (skala intensitas 0-255) |
| | `minBlock` / `minRegion` | ukuran blok terkecil (px) dan luas region minimal (px) |
| Semantic | - | model dan daftar kelas mengikuti model bagian D |

Nilai default sudah disetel untuk citra BSDS500 (481x321): bagian C memakai
`minBlock` 16 px, `minRegion` 1500 px, dan `Tsplit = Tmerge` 25 (predikat `std`)
atau 60 (predikat `range`), sehingga satu citra menghasilkan puluhan region,
bukan ribuan. Threshold tetap boleh disesuaikan per citra.

### Catatan saat menjalankan

- Tab **Semantic**: Run pertama butuh sekitar 15 detik (menyalakan proses Python
  dan memuat model), selanjutnya sekitar 0,3-0,5 detik per citra di CPU. Kalau
  Python belum disiapkan (langkah 2), tab ini menampilkan pesan error yang
  menjelaskan langkahnya; tab Edge Detection dan Split & Merge tetap dapat dipakai.
- Pada citra bertekstur sangat padat, semua region hasil pengisian kontur bisa
  menyentuh tepi citra. Program tidak mengembalikan mask kosong: filter
  `clearBorder` dilewati dan status bar menuliskan
  `border fallback (semua region menyentuh tepi)`.
- Kalau muncul `Undefined function 'SegmentationApp'`, path belum ditambahkan -
  ulangi langkah 3.

## Bagian D: Segmentasi Semantik (CNN)

### Model

**DeepLabV3+** dengan encoder **ResNet-18** pretrained ImageNet
([segmentation-models-pytorch](https://github.com/qubvel-org/segmentation_models.pytorch)).
Encoder pretrained di-fine-tune bersama decoder baru dan head 11 kelas (transfer learning).

### Dataset CamVid

CamVid (701 frame berlabel, 720x960) tidak disimpan di repositori. Pranala sumber:

- Citra: http://web4.cs.ucl.ac.uk/staff/g.brostow/MotionSegRecData/files/701_StillsRaw_full.zip
- Label piksel: http://web4.cs.ucl.ac.uk/staff/g.brostow/MotionSegRecData/data/LabeledApproved_full.zip

Pelatihan memakai versi Kaggle dari CamVid (frame yang sama, dengan `class_dict.csv`
dan pembagian `train/val/test` standar).

**Pembagian data:** 369 train / 100 validasi / 232 test. Ini pembagian standar CamVid
yang memisahkan frame per sekuens video, sehingga frame yang hampir identik tidak
muncul sekaligus di data latih dan data uji.

**Pengelompokan kelas (32 → 11):**

| Kelas | Kelas asli CamVid |
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
| *(diabaikan)* | Void |

### Pelatihan

Notebook: [`notebooks/tugas-3-pengolahan-citra-digital.ipynb`](notebooks/tugas-3-pengolahan-citra-digital.ipynb),
dijalankan di Kaggle (GPU T4).

| Pengaturan | Nilai |
|---|---|
| Ukuran input | 384x512 (CamVid diperkecil, rasio 3:4 tetap) |
| Augmentasi | skala acak 0,75-1,25, random crop, flip horizontal |
| Loss | cross-entropy per piksel, bobot kelas median-frequency, Void diabaikan |
| Optimizer | AdamW, LR 1e-4 (encoder) / 1e-3 (decoder + head), weight decay 1e-4 |
| Jadwal LR | polynomial decay (power 0,9) |
| Epoch / batch | 80 / 8, checkpoint terbaik dipilih dari mIoU validasi |

Semua pengaturan juga tersimpan di [`notebooks/output/config.json`](notebooks/output/config.json).

**Melatih ulang:** unggah notebook ke Kaggle, tambahkan dataset CamVid sebagai input,
aktifkan GPU dan Internet, lalu **Save & Run All**. Unduh `best_model.pth` (bisa
terunduh sebagai `best_model.zip`) dan `config.json` ke `notebooks/output/`.

### Hasil (data uji CamVid, 232 citra, resolusi penuh 720x960)

| Metrik | Nilai |
|---|---|
| Global pixel accuracy | 0,912 |
| Mean class accuracy | 0,837 |
| Mean IoU | 0,679 |

| Kelas | IoU | Kelas | IoU |
|---|---|---|---|
| Sky | 0,919 | SignSymbol | 0,466 |
| Building | 0,840 | Fence | 0,551 |
| Pole | 0,276 | Car | 0,817 |
| Road | 0,940 | Pedestrian | 0,501 |
| Pavement | 0,773 | Bicyclist | 0,595 |
| Tree | 0,789 | | |

Gambar pendukung (confusion matrix, contoh prediksi, kurva pelatihan) ada di
`notebooks/output/`.

### Alur pemanggilan dari GUI

`SegmentationApp` → `segmentSemantic(img)` (MATLAB) → `semantic_predict.predict()` (Python):
citra diperkecil ke 384x512 dan dinormalisasi, network menghasilkan skor kelas, skor
diperbesar kembali ke ukuran asli, lalu kelas dengan skor tertinggi dipilih per piksel.
`segmentSemantic` mengembalikan citra label (1-11), nama kelas, dan warna kelas.
Python dijalankan sebagai proses terpisah (`ExecutionMode = OutOfProcess`) supaya
library native PyTorch tidak bentrok dengan library MATLAB.

## Struktur Berkas

```
src/
  SegmentationApp.m        GUI utama (3 tab)
  core/                    utilitas bersama: konvolusi, Otsu, registri parameter,
                           label-to-RGB, serta pipeline applyEdgeSegmentation dan
                           applySplitMerge yang dipanggil GUI
  b-edge-detection/        bagian B: 6 operator tepi, zero-crossing, mask objek
  c-split-merge/           bagian C: quadtree split, region adjacency, merge
  d-semantic/              bagian D: segmentSemantic.m (jembatan MATLAB-Python)
                           dan semantic_predict.py (inferensi PyTorch)
notebooks/
  tugas-3-...ipynb         notebook pelatihan bagian D (Kaggle)
  output/                  bobot model (best_model.zip), config.json, metrik, gambar
data/
  bsds500/                 8 citra uji bagian B dan C
  README.md                keterangan data dan pranala unduh CamVid
docs/
  gui_preview.jpg          tangkapan layar GUI untuk README
```

## Data Uji

- **BSDS500**: 8 citra pada `data/bsds500/`, dipakai untuk bagian B dan C.
- **CamVid** (bagian D): tidak disimpan di repositori karena ukurannya besar.
  Pranala unduh ada di [`data/README.md`](data/README.md) dan di bagian
  [Bagian D](#bagian-d-segmentasi-semantik-cnn); dataset diletakkan di `data/camvid/`.

## Lisensi

[MIT License](LICENSE)
