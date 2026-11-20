function [L, classNames, cmap] = segmentSemantic(img) %#ok<INUSD,STOUT>
%SEGMENTSEMANTIC Titik masuk Part D yang dipanggil GUI (tab Semantic).
%   *** Masih harus diisi Person 2 (deep learning). ***
%
%   Kontrak yang diharapkan SegmentationApp:
%     img        : citra RGB uint8 berukuran H-by-W-by-3
%     L          : label image (numerik 0..K atau categorical),
%                  0/tak terdefinisi berarti belum berlabel
%     classNames : cellstr 1-by-K, misalnya {'Sky','Building','Pole','Road',
%                  'Pavement','Tree','SignSymbol','Fence','Car',
%                  'Pedestrian','Bicyclist'}
%     cmap       : warna K-by-3 pada rentang [0,1], baris ke-k warna kelas k
%
%   L boleh lebih kecil atau lebih besar dari img (mengikuti ukuran input
%   network); GUI yang menyesuaikan ukuran citra untuk overlay. Kalau pakai
%   Python, bungkus pemanggilan py.* di sini supaya GUI hanya melihat satu
%   fungsi MATLAB ini saja.
    error('segmentSemantic:notImplemented', ...
        'Model semantic segmentation belum tersedia (bagian Person 2).');
end
