function [delays, data_cube, name ] =  OMERO_fetch(obj, image, channel, ZCT, mdta)

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

   
    
data_cube = [];

name = char(image.getName.getValue());

FLIM_type   = mdta.FLIM_type;
modulo      = mdta.modulo;
n_channels  = mdta.n_channels;
delays      = mdta.delays';

if isempty(modulo)    
    errordlg('no suitable annotation found - can not continue');
    return;
else

    if ~isempty(mdta.n_channels) && mdta.SizeC~=1 && mdta.n_channels == mdta.SizeC && ~strcmp(mdta.modulo,'ModuloAlongC') % native multi-spectral FLIM     
        data_cube_ = get_FLIM_cube_Channels( obj.session, image, mdta.modulo, ZCT );
    else 
        data_cube_ = get_FLIM_cube( obj.session, image, n_channels, channel, modulo, ZCT );                
    end
            
    [nBins,sizeX,sizeY] = size(data_cube_);       
    data_cube = zeros(nBins,1,sizeX,sizeY,1);
    
    data_cube(1:end,1,:,:,1) = squeeze(data_cube_(1:end,:,:));  
    
    %Bodge to suppress bright line artefact on RHS in BH .sdt files
    if strfind(name,'.sdt')
       data_cube(:,:,:,end,:) = 0;
    end
    
    if FLIM_type ~= 'TCSPC'
        if min(data_cube(:)) > 32500
            data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
        end
    end
      
end
   