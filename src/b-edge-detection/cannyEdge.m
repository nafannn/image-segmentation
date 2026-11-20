function [E, M] = cannyEdge(G, low, high, sigma)
%CANNYEDGE Detektor edge Canny memakai fungsi bawaan MATLAB EDGE.
%   [E, M] = cannyEdge(G, low, high, sigma)
%     G         : citra gray double pada rentang [0, 255]
%     low, high : threshold hysteresis T1 < T2, ditulis pecahan 0..1
%     sigma     : simpangan baku Gaussian smoothing
%   E : binary edge map (tebal 1 piksel setelah non-maximum suppression dan
%       hysteresis: edge kuat > T2 ditambah edge lemah > T1 yang nyambung)
%   M : gradient magnitude Sobel setelah smoothing, hanya untuk ditampilkan
%       sebagai respons
    if low >= high
        error('cannyEdge:thresholds', ...
            'Low threshold (T1 = %.3g) harus lebih kecil dari high threshold (T2 = %.3g).', low, high);
    end
    E = edge(G / 255, 'canny', [low high], sigma);

    % Respons untuk tampilan dihitung ulang: smoothing Gaussian dulu,
    % lalu gradien Sobel
    Gs = myConv2(G, gaussianKernel(sigma));
    M = sobelEdge(Gs);
end
