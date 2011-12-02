function z = otsu_oht_segmentation(U,S,sensitivity,smooth_scale,min_size)

se = strel('disk',round(S));
J = map(imsubtract(imadd(U,imtophat(U,se)),imbothat(U,se)),0,1);

otsu_level = graythresh(J);
t = abs(otsu_level/sensitivity);

se = strel('disk',smooth_scale);

b1 = im2bw(J,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);

