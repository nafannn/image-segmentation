function [M, Gx, Gy] = robertsEdge(G)
%ROBERTSEDGE Roberts cross operator (own implementation).
%   [M, Gx, Gy] = robertsEdge(G) on a double gray image G.
%   Gradient along the two diagonals (lecture 19, "operator silang"):
%       R+ = [1  0;  0 -1]   ->  f(x,y) - f(x+1,y+1)
%       R- = [0  1; -1  0]   ->  f(x+1,y) - f(x,y+1)
%   Edge strength M = sqrt(R+^2 + R-^2).
    Rp = [1 0; 0 -1];
    Rm = [0 1; -1 0];
    Gx = myConv2(G, Rp);
    Gy = myConv2(G, Rm);
    M = sqrt(Gx.^2 + Gy.^2);
end
