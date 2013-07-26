function z = otsu_oht_segmentation(U,scale,sensitivity,smoothing,min_size)
%Histogram based object segmentation including local background removal 
%scale=100,sensitivity=1,threshold=0.01,smoothing=5,min_area=200
%scale,Object width (pixels)
%sensitivity,Adjustment to calculated threshold (~1, greater to expand area)
%smoothing,Radius of smoothing kernel (pixels)
%min_area,Minimium object area (pixels)


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

se = strel('disk',max(1,round(abs(S))));
J = map(imsubtract(imadd(U,imtophat(U,se)),imbothat(U,se)),0,1);

otsu_level = graythresh(J);
t = min(1,abs(otsu_level/sensitivity));

se = strel('disk',max(1,round(abs(smoothing))));

b1 = im2bw(J,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);

