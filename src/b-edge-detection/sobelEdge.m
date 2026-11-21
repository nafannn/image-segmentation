function [M, Gx, Gy] = sobelEdge(G)
%SOBELEDGE Operator Sobel (gradien 3x3).
%   Beda pusat dengan baris/kolom tengah diberi bobot c = 2, jadi ada
%   sedikit smoothing tegak lurus arah turunannya:
%       Sx = [-1 0 1; -2 0 2; -1 0 1]
%       Sy = [ 1 2 1;  0 0 0; -1 -2 -1]
%   Kekuatan edge M = sqrt(Sx^2 + Sy^2).
    c = 2;
    Sx = [-1 0 1; -c 0 c; -1 0 1];
    Sy = [1 c 1; 0 0 0; -1 -c -1];
    Gx = myConv2(G, Sx);
    Gy = myConv2(G, Sy);
    M = sqrt(Gx.^2 + Gy.^2);
end
