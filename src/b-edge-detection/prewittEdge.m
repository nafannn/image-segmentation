function [M, Gx, Gy] = prewittEdge(G)
%PREWITTEDGE Operator Prewitt (implementasi sendiri).
%   Skema turunannya sama dengan Sobel, bedanya bobot tengah c = 1:
%       Px = [-1 0 1; -1 0 1; -1 0 1]    (horizontal berubah -> edge vertikal)
%       Py = [ 1 1 1;  0 0 0; -1 -1 -1]  (vertikal berubah -> edge horizontal)
%   Kekuatan edge M = sqrt(Gx^2 + Gy^2).
    c = 1;
    Px = [-1 0 1; -c 0 c; -1 0 1];
    Py = [1 c 1; 0 0 0; -1 -c -1];
    Gx = myConv2(G, Px);
    Gy = myConv2(G, Py);
    M = sqrt(Gx.^2 + Gy.^2);
end
