function [ path,name,ext ] = fileparts_inc_OME( file )
% split filename into 3 allowing for ome_tiffs

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

    [path,name,ext] = fileparts(file);

    if strcmp(ext,'.tiff')
        ext = '.tif';
    end
    
    if strcmp(ext,'.tif')
         if length(name) > 3
             tail = (name(end-3:end));
             if strcmpi(tail,'.ome')  || strcmpi(tail,'.o.e')
                ext = '.ome';
                name = name(1:end-4);
             end
         end
    end

end

