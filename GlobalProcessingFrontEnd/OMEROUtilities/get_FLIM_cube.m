function data_cube = get_FLIM_cube( session, image, n_blocks, block, modulo, ZCT )

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
    %
    if ~strcmp(modulo,'ModuloAlongC') && ~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
        [ST,I] = dbstack('-completenames');
        errordlg(['No acceptable ModuloAlong* in the function ' ST.name]);
        return;
    end;    
    %
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
    %
    sizeX = pixels.getSizeX().getValue();
    sizeY = pixels.getSizeY().getValue();
    sizeC = pixels.getSizeC().getValue();
    sizeT = pixels.getSizeT().getValue();
    sizeZ = pixels.getSizeZ().getValue();
    %
    pixelsId = pixels.getId().getValue();
    image.getName().getValue();
        store = session.createRawPixelsStore(); 
        store.setPixelsId(pixelsId, false);    
    % 
    %
       switch modulo
            case 'ModuloAlongZ' 
                N = sizeZ;        
            case 'ModuloAlongC' 
                N = sizeC;        
            case 'ModuloAlongT' 
                N = sizeT;        
        end    
    %
    if 0 == block || isempty(n_blocks) || isempty(block) || n_blocks < block
        c_begin = 1;
        c_end = N;
    else
        n_channels = floor(N/n_blocks);
        %
        c_begin = 1 + n_channels*(block - 1);
        c_end = c_begin + n_channels - 1;        
    end
    %
    data_cube = zeros(c_end - c_begin + 1, sizeY, sizeX);            
    %
    Z = ZCT(1)-1;
    C = ZCT(2)-1;
    T = ZCT(3)-1;
    
    w = waitbar(0, 'Loading FLIMage....');
        
    for c = c_begin:c_end,
        switch modulo % getPlane(Z,C,T)
            case 'ModuloAlongZ' 
                rawPlane = store.getPlane(c - 1, C, T );        
            case 'ModuloAlongC' 
                rawPlane = store.getPlane(Z, c - 1, T);        
            case 'ModuloAlongT' 
                rawPlane = store.getPlane(Z, C, c - 1);        
        end
        %
        plane = toMatrix(rawPlane, pixels); 
            data_cube(c - c_begin + 1,:,:) = plane';
        %
        waitbar(c/(c_end-c_begin),w);
        drawnow;
        %
    end

    delete(w);
    drawnow;
    
    store.close();

end

