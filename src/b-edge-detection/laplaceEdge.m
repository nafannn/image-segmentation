function L = laplaceEdge(G, neighbors)
%LAPLACEEDGE Respons Laplace (turunan kedua), implementasi sendiri.
%   L = laplaceEdge(G, neighbors) mengembalikan Laplacian bertanda dari G.
%   Edge tidak ada di tempat L besar, tapi di tempat L berganti tanda
%   (zero-crossing). Karena itu L masih harus diumpan ke zeroCrossing.
%     neighbors = 4 : [0 1 0; 1 -4 1; 0 1 0]   hanya tetangga atas/bawah/kiri/kanan
%     neighbors = 8 : [1 1 1; 1 -8 1; 1 1 1]   diagonal ikut dihitung
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
