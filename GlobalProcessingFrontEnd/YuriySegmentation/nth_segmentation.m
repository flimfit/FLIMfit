function z = nth_segmentation(U,scale,rel_bg_scale,threshold,smoothing,min_area) 
%Object segmentation based on local thresholding
%scale=100,rel_bg_scale=2,threshold=0.1,smoothing=5,min_area=200
%scale,Object width (pixels)
%rel_bg_scale,Background size used to calculate threshold/Object width (>1)
%threshold,Threshold (0-1)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixels^2)

S = scale;
K = rel_bg_scale;
t = threshold;
se = strel('disk',max(1,round(abs(smoothing))));

se20 = strel('disk',20);


if K<1
    K=1;
end

% nonlinear tophat + otsu thersholded
nth = nonlinear_tophat(U,S,K)-1;

norm = max(nth(:));
norm = min(norm,10000);
nth = nth / norm;
t = t / norm;

t = max(t,0);
t = min(t,1);

b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

%clf

L = bwlabel(b1);
stats = regionprops(L,'Area','Eccentricity');
idx = find([stats.Area] > min_area & [stats.Eccentricity] < 1);
z = ismember(L,idx);

z = bwlabel(z);
return

%{
sez = strel('disk',10);
ze = imdilate(z,sez); %z = imerode(z,se);

%imagesc(z);
ue = imerode(z,se20);
%imagesc(ue);

ue = bwulterode(ue);
d = bwdist(ue);
ue = d < 20;

I = imimposemin(imcomplement(U), ue | ~ze); 
%imagesc(ue | ~z)
L = watershed(I); 
L(~z) = 0;
%imagesc(L)

stats = regionprops(L,'Area','Eccentricity');
idx = find([stats.Area] > min_area & [stats.Eccentricity] < 1);
L(~ismember(L,idx)) = 0;
%imagesc(L)

z = L-1;
%}