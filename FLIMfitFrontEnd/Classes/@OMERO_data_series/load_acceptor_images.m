function load_acceptor_images(obj,id_list,~)                        
    % data_series MUST BE initiated BEFORE THE CALL OF THIS FUNCTION  
        
        
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

    imageList = getImages(obj.omero_data_manager.session,id_list);

    image = imageList(1);
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);                        
    SizeC = pixels.getSizeC().getValue();
    SizeZ = pixels.getSizeZ().getValue();
    SizeT = pixels.getSizeT().getValue();    
    
    if (SizeZ~=1 || SizeC~=1 || SizeT~=1), errordlg('cant load acceptor images - single plane images expcted'), return, end;
    
    SizeX = pixels.getSizeY().getValue(); % transposed
    SizeY = pixels.getSizeX().getValue();

    n_images = numel(imageList);
    
    obj.acceptor = zeros(SizeX,SizeY,n_images);    

    store = obj.omero_data_manager.session.createRawPixelsStore();     
    
    for k = 1 : n_images                
        image = imageList(k);
        pixelsList = image.copyPixels();    
        pixels = pixelsList.get(0);                               
        pixelsId = pixels.getId().getValue();
        store.setPixelsId(pixelsId, false);          
        rawPlane = store.getPlane(0, 0, 0 ); % single plane expected               
        plane = toMatrix(rawPlane, pixels); 
        obj.acceptor(:,:,k) = plane';                        
    end
            
end            














