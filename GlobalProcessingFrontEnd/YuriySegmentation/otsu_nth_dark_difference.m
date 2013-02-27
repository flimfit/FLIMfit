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