function zl = membrane_segmentation(U, edge_sensitivity, membrane_width, min_size)
%Segment cell membrane by edge detection and dilation
%edge_sensitivity=0.5,membrane_width=4,min_size=1000
%edge_sensitivity,Sensitivity to edges (0-1)
%membrane_width,Width of membrane (pixels)
%min_size,Minimium object area (pixel^2)


[~, threshold] = edge(U, 'sobel');
BWs = edge(U,'sobel', threshold * edge_sensitivity);

se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);
BWsdil = imdilate(BWs, [se90 se0]);

BWdfill = imfill(BWsdil, 'holes');

BWnobord = imclearborder(BWdfill, 8);

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);

se = strel('disk',membrane_width);
BWerode = imerode(BWfinal,se);
%BWerode=bwmorph(logical(BWfinal), 'erode', membrane_width);

z = BWfinal - BWerode;

zl = bwlabel(z,4);

if max(z(:)) > 0
stats = regionprops(zl,{'Area'});
s = cell2mat(struct2cell(stats));

area = s(1,:);
filt = area > min_size;

for i=1:length(area)
    if ~filt(i)
        z(zl==i) = 0;
    end
end

zl = bwlabel(z,4);
else
    zl = z;
end