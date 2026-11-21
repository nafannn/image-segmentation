function showImageOnAxes(ax, img)
%SHOWIMAGEONAXES Tampilkan citra pada UIAXES ax. Coba IMSHOW dulu
%   (Image Processing Toolbox); kalau tidak tersedia, jatuh ke IMAGE/IMAGESC
%   biasa supaya app tetap jalan tanpa toolbox.
    cla(ax);
    if isempty(img)
        ax.XTick = [];
        ax.YTick = [];
        return;
    end
    try
        imshow(img, 'Parent', ax);
    catch
        if ismatrix(img)
            imagesc(ax, img);
            colormap(ax, gray(256));
        else
            image(ax, img);
        end
        axis(ax, 'image');
    end
    ax.XTick = [];
    ax.YTick = [];
end
