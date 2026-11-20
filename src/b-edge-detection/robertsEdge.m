function [M, Gx, Gy] = robertsEdge(G)
%ROBERTSEDGE Operator Roberts cross (implementasi sendiri).
%   [M, Gx, Gy] = robertsEdge(G) untuk citra gray double G.
%   Gradient dihitung sepanjang dua diagonal (operator silang):
%       R+ = [1  0;  0 -1]   ->  f(x,y) - f(x+1,y+1)
%       R- = [0  1; -1  0]   ->  f(x+1,y) - f(x,y+1)
%   Kekuatan edge M = sqrt(R+^2 + R-^2).
    Rp = [1 0; 0 -1];
    Rm = [0 1; -1 0];
    Gx = myConv2(G, Rp);
    Gy = myConv2(G, Rm);
    M = sqrt(Gx.^2 + Gy.^2);
end
