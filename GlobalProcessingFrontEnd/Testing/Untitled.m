
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

% Author : Sean Warren

folder = 'C:\Users\scw09\Documents\Local FLIM Data\2010-12-20 Cliff Nano Simulation\EvenAmps 50000 photons Old\';

flimage = zeros(256,64,64);

for col=1:64
    for row=1:64
        
        data = dlmread([folder 'col ' num2str(col) ' pix ' num2str(row) '.txt']);
        times = data(:,1);
        decay = data(:,2);
                
        flimage(:,row,col) = decay;
   
    end
end

%%

flimage = uint16(flimage);

folder = 'C:\Users\scw09\Documents\Local FLIM Data\2010-12-20 Cliff Nano Simulation\TifData\';

for i=1:256
   
    imwrite(squeeze(flimage(i,:,:)),[folder 'del' sprintf('%05.0f',times(i)*1000) '.tif']);
    
end