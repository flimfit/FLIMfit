function zl = membrane_segmentation(U, edge_sensitivity, membrane_width, min_size)
%Segment cell membrane by edge detection and dilation
%edge_sensitivity=0.5,membrane_width=4,min_size=1000
%edge_sensitivity,Sensitivity to edges (0-1)
%membrane_width,Width of membrane (pixels)
%min_size,Minimium object area (pixel^2)


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



[~, threshold] = edge(U, 'sobel');
BWs = edge(U,'sobel', threshold * edge_sensitivity);

se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);
BWsdil = imdilate(BWs, [se90 se0]);

BWdfill = imfill(BWsdil, 'holes');

BWnobord = imclearborder(BWdfill, 8);

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);

se = strel('disk',membrane_width);
BWerode = imerode(BWfinal,se);
%BWerode=bwmorph(logical(BWfinal), 'erode', membrane_width);

z = BWfinal - BWerode;

zl = bwlabel(z,4);

if max(z(:)) > 0
stats = regionprops(zl,{'Area'});
s = cell2mat(struct2cell(stats));

area = s(1,:);
filt = area > min_size;

for i=1:length(area)
    if ~filt(i)
        z(zl==i) = 0;
    end
end

zl = bwlabel(z,4);
else
    zl = z;
end