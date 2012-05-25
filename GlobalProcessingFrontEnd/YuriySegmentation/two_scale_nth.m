function z = two_scale_nth(U,scale1,rel_bg_scale1,scale2,rel_bg_scale2,threshold,smoothing,min_size)
%Two scale object segmentation for ovoid or long objects based on local thresholding
%scale1=100,rel_bg_scale1=2,scale2=200,rel_bg_scale2=4,threshold=0.01,smoothing=5,min_area=200
%scale1,Object width (pixels)
%rel_bg_scale1,Background size used to calculate threshold/Object width
%scale2,Object height (pixels)
%rel_bg_scale2,Background size used to calculate threshold/Object width
%threshold,Threshold (0-1)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area

S1 = scale1;
K1 = rel_bg_scale1;
S2 = scale2;
K2 = rel_bg_scale2;
t = threshold;

if t > 1
    t = 1;
end

se = strel('disk',max(1,round(abs(smoothing))));

nth1 = nonlinear_tophat(U,S1,K1)-1;
nth2 = nonlinear_tophat(U,S2,K2)-1;

nth = pixelwise_max(nth1,nth2);
nth = (nth+abs(nth))/2;
b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);
