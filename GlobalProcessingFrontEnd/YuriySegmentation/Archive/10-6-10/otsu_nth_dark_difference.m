function z = otsu_nth_dark_difference(U,S1,K1,t1,S,sensitivity,smooth_scale,min_size)

se = strel('disk',smooth_scale);

z1 = nth_segmentation(U,S1,K1,t1,smooth_scale,min_size);
%zr goes via otsu
z2 = otsu_oht_segmentation(U,S,sensitivity,smooth_scale,min_size); 

b1 = im2bw(z1,1);
b2 = im2bw(z2,1);
b1 = b2-b1; b1 = (b1+abs(b1))/2;
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);