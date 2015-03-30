function z = two_scale_nth(U,scale1,rel_bg_scale1,scale2,rel_bg_scale2,threshold,smoothing,min_size)
%Two scale object segmentation for ovoid or long objects based on local thresholding
%scale1=100,rel_bg_scale1=2,scale2=200,rel_bg_scale2=4,threshold=0.01,smoothing=5,min_area=200
%scale1,Object width (pixels)
%rel_bg_scale1,Background size used to calculate threshold/Object width
%scale2,Object height (pixels)
%rel_bg_scale2,Background size used to calculate threshold/Object width
%threshold,Threshold (0 or greater)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area


%
% Copyright (C) 2013 Imperial College London.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% This software tool was developed with support from the UK 
% Engineering and Physical Sciences Council 
% through  a studentship from the Institute of Chemical Biology 
% and The Wellcome Trust through a grant entitled 
% "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

S1 = scale1;
K1 = rel_bg_scale1;
S2 = scale2;
K2 = rel_bg_scale2;
t = threshold;

se = strel('disk',max(1,round(abs(smoothing))));

nth1 = nonlinear_tophat(U,S1,K1)-1;
nth2 = nonlinear_tophat(U,S2,K2)-1;

norm1 = max(nth1(:));
norm2 = max(nth2(:));
norm1 = max(norm1,norm2);
norm1 = min(norm1,10000);

nth1 = nth1 / norm1;
nth2 = nth2 / norm1;
t = t / norm1;



nth = pixelwise_max(nth1,nth2);
nth = (nth+abs(nth))/2;
b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);
