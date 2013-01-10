function z = nth_membrane_segmentation(U,scale,rel_bg_scale,threshold,membrane_width,smoothing,min_area) 
%Object segmentation based on local thresholding
%scale=100,rel_bg_scale=2,threshold=0.1,membrane_width=4,smoothing=5,min_area=200
%scale,Object width (pixels)
%rel_bg_scale,Background size used to calculate threshold/Object width (>1)
%threshold,Threshold (0-1)
%membrane_width,Width of membrane (pixels)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixels^2)

S = scale;
K = rel_bg_scale;
t = threshold;
se = strel('disk',max(1,round(abs(smoothing))));

if K<1
    K=1;
end


% nonlinear tophat + otsu thersholded
nth = nonlinear_tophat(U,S,K)-1;

norm = max(nth(:));
norm = min(norm,10000);
nth = nth / norm;
t = t / norm;

b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_area);
z = ismember(L,idx);
z = logical(z);

se = strel('disk',membrane_width);
z_erode = imerode(z,se);
%z_erode = bwmorph(z, 'erode', membrane_width);

z = z - z_erode;

z = bwlabel(z);



