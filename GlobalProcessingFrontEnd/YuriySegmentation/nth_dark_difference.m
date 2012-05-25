function z = nth_dark_difference(U,scale1,rel_bg_scale1,threshold1,scale2,rel_bg_scale2,threshold2,smoothing,min_size)
%Object segmentation rejecting a bright centre (e.g. bright nucleus)
%scale1=100,rel_bg_scale1=2,threshold1=0.1,scale2=200,rel_bg_scale2=4,threshold2=0.1,smoothing=5,min_area=200
%scale1,Width of bright nucleus within desired object (pixels)
%rel_bg_scale1,Background size used to calculate threshold/Object width
%threshold1,Threshold for bright nucleus(0-1)
%scale2,Width of desired object (pixels)
%rel_bg_scale2,Background size used to calculate threshold/Object width
%threshold2,Threshold for cytoplasm (0-1)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixel^2)

S1 = scale1;
S2 = scale2;
K1 = rel_bg_scale1;
K2 = rel_bg_scale2;
t1 = threshold1;
t2 = threshold2;

se = strel('disk',max(1,round(abs(smoothing))));

z1 = nth_segmentation(U,S1,K1,t1,smoothing,min_size);
z2 = nth_segmentation(U,S2,K2,t2,smoothing,min_size);

b1 = z1 > 0;
b2 = z2 > 0;
b1 = b2 & ~b1;
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);