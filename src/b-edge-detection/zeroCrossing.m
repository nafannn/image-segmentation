function [S, Z] = zeroCrossing(L)
%ZEROCROSSING Locate sign changes of a second-derivative response.
%   [S, Z] = zeroCrossing(L)
%     L : signed Laplace / LoG response
%     Z : logical map of pixels where L changes sign with a neighbor
%     S : strength of the crossing = |L(p) - L(q)| (the "slope" across it),
%         0 where there is no crossing. Thresholding S removes the weak
%         crossings caused by noise and tiny intensity ripples.
%   Neighbors checked: right, down, down-right, down-left. A crossing is
%   assigned to the pixel of the pair with the smaller |L| (the one closer
%   to the true zero), which keeps edges one pixel thin.
    [H, W] = size(L);
    S = zeros(H, W);
    absL = abs(L);
    offsets = [0 1; 1 0; 1 1; 1 -1];       % [drow dcol]

    for k = 1:size(offsets, 1)
        dr = offsets(k, 1);
        dc = offsets(k, 2);
        % Index ranges so that p = (r, c) and q = (r+dr, c+dc) are both inside
        r = 1:H - dr;
        if dc >= 0
            c = 1:W - dc;
        else
            c = 1 - dc:W;
        end
        Lp = L(r, c);
        Lq = L(r + dr, c + dc);
        cross = (Lp .* Lq) < 0;             % opposite signs -> zero in between
        slope = abs(Lp - Lq) .* cross;

        % Give the crossing to whichever pixel is nearer to zero
        toP = cross & (absL(r, c) <= absL(r + dr, c + dc));
        toQ = cross & ~toP;

        Sp = S(r, c);
        Sp(toP) = max(Sp(toP), slope(toP));
        S(r, c) = Sp;

        Sq = S(r + dr, c + dc);
        Sq(toQ) = max(Sq(toQ), slope(toQ));
        S(r + dr, c + dc) = Sq;
    end
    Z = S > 0;
end
