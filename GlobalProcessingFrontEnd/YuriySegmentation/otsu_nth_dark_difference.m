function z = otsu_nth_dark_difference(U,scale1,rel_bg_scale1,threshold1,scale2,sensitivity,smoothing,min_area)
%Histogram based object segmentation rejecting a bright centre (e.g. bright nucleus)
%scale1=100,rel_bg_scale1=2,threshold1=0.1,scale2=200,sensitivity=1,smoothing=5,min_area=200
%scale1,Width of bright nucleus within desired object (pixels)
%rel_bg_scale1,Background size used to calculate threshold/Object width
%threshold1,Threshold for bright nucleus(0-1)
%scale2,Width of desired object (pixels)
%sensitivity,Adjustment to calculated threshold (~1, greater to expand area)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixel^2)

se = strel('disk',smoothing);

S1 = scale1;
K1 = rel_bg_scale1; 
t1 = threshold1;
S = scale2;

z1 = nth_segmentation(U,S1,K1,t1,smoothing,min_area);
%zr goes via otsu
z2 = otsu_oht_segmentation(U,S,sensitivity,smoothing,min_area); 

b1 = im2bw(z1,1);
b2 = im2bw(z2,1);
b1 = b2-b1; b1 = (b1+abs(b1))/2;
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_area);
z = ismember(L,idx);
z = bwlabel(z);