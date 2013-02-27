function z = nth_membrane_segmentation(U,scale,rel_bg_scale,threshold,membrane_width,smoothing,min_area) 
%Object segmentation based on local thresholding
%scale=100,rel_bg_scale=2,threshold=0.1,membrane_width=4,smoothing=5,min_area=200
%scale,Object width (pixels)
%rel_bg_scale,Background size used to calculate threshold/Object width (>1)
%threshold,Threshold (0-1)
%membrane_width,Width of membrane (pixels)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixels^2)



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



