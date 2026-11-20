function L = laplaceEdge(G, neighbors)
%LAPLACEEDGE Laplace (second-derivative) response, own implementation.
%   L = laplaceEdge(G, neighbors) returns the signed Laplacian of G.
%   Edges are NOT where L is large but where L changes sign
%   (zero-crossing), so pass L to zeroCrossing afterwards.
%     neighbors = 4 : [0 1 0; 1 -4 1; 0 1 0]   (lecture 18, slide 55)
%     neighbors = 8 : [1 1 1; 1 -8 1; 1 1 1]   (slide 57, also diagonals)
    if nargin < 2
        neighbors = 8;
    end
    if neighbors == 4
        H = [0 1 0; 1 -4 1; 0 1 0];
    else
        H = [1 1 1; 1 -8 1; 1 1 1];
    end
    L = myConv2(G, H);
end
