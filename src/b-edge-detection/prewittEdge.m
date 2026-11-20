function [M, Gx, Gy] = prewittEdge(G)
%PREWITTEDGE Prewitt operator (own implementation).
%   Same derivative scheme as Sobel but with weight c = 1 (lecture 19):
%       Px = [-1 0 1; -1 0 1; -1 0 1]     (horizontal change -> vertical edges)
%       Py = [ 1 1 1;  0 0 0; -1 -1 -1]   (vertical change   -> horizontal edges)
%   Edge strength M = sqrt(Gx^2 + Gy^2).
    c = 1;
    Px = [-1 0 1; -c 0 c; -1 0 1];
    Py = [1 c 1; 0 0 0; -1 -c -1];
    Gx = myConv2(G, Px);
    Gy = myConv2(G, Py);
    M = sqrt(Gx.^2 + Gy.^2);
end
