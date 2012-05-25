function z = otsu_oht_segmentation(U,scale,sensitivity,smoothing,min_size)
%Histogram based object segmentation including local background removal 
%scale=100,sensitivity=1,threshold=0.01,smoothing=5,min_area=200
%scale,Object width (pixels)
%sensitivity,Adjustment to calculated threshold (~1, greater to expand area)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixels)

S = scale;

se = strel('disk',max(1,round(abs(S))));
J = map(imsubtract(imadd(U,imtophat(U,se)),imbothat(U,se)),0,1);

otsu_level = graythresh(J);
t = min(1,abs(otsu_level/sensitivity));

se = strel('disk',max(1,round(abs(smoothing))));

b1 = im2bw(J,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);

