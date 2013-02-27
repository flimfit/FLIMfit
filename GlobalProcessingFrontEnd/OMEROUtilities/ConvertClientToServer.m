function [ byteStream ] = ConvertClientToServer(  pixels, data )
%fromMatrix converts a 2d matlab array to a bytestream 
%   ready to use in OMERO rawDataStore.setPlane
% possible replacement for GatewayUtils convertClienttoServer

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
        


             
    [ sizeX sizeY ] = size(data);

    sizexp = pixels.getSizeX().getValue();
    sizeyp = pixels.getSizeY().getValue();

    if sizeX ~= sizexp || sizeY ~= sizeyp
        return;
    end

    pixType = char(pixels.getPixelsType().getValue().getValue());
    
    if ~strcmp(class(data), pixType)
        %NB casting like this is dodgy!! Better to throw an error
        data = cast(data,pixType);
    end

    ar = reshape(data, sizeX * sizeY, 1 );
    ar = swapbytes(ar);     % not quite sure why? Copied from toMatrix
    byteStream = typecast(ar, 'int8');
    

end

