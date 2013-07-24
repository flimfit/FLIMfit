function write_flim_tifs(folder,t,data)
% write_flim_tifs writes data into a folder as tifs using Photonics
% filename conventions

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


    folder = ensure_trailing_slash(folder);

    sz = size(data);

    if ndims(data) == 4 && sz(2) == 1
        data = reshape(data,[sz(1) sz(3:end)]);
    end

    for i=1:length(t)
       
       plane = data(i,:,:);
       plane = squeeze(plane); 
       
       name = [folder 'T_' num2str(t(i),'%05d') '.tif'];
       
       imwrite(plane,name); 
        
    end

end