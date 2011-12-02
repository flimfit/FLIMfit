function z = nth_segmentation(U,S,K,t,smooth_scale,min_size)
% U - an original grayscale image
% S - chatracteristic scale
% t - sensitivity threshold

se = strel('disk',max(1,round(abs(smooth_scale))));

% nonlinear tophat + otsu thersholded
nth = nonlinear_tophat(U,S,K)-1;
%nth = (nth+abs(nth))/2;
b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

%z = b1;

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);




