function [M, Gx, Gy] = sobelEdge(G)
%SOBELEDGE Sobel operator (own implementation).
%   Central differences with the middle row/column weighted c = 2, which
%   adds a little smoothing perpendicular to the derivative (lecture 19):
%       Sx = [-1 0 1; -2 0 2; -1 0 1]
%       Sy = [ 1 2 1;  0 0 0; -1 -2 -1]
%   Edge strength M = sqrt(Sx^2 + Sy^2).
    c = 2;
    Sx = [-1 0 1; -c 0 c; -1 0 1];
    Sy = [1 c 1; 0 0 0; -1 -c -1];
    Gx = myConv2(G, Sx);
    Gy = myConv2(G, Sy);
    M = sqrt(Gx.^2 + Gy.^2);
end
