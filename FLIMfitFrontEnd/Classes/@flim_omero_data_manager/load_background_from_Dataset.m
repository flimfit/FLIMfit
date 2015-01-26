function load_background_from_Dataset(obj,data_series,dataset)

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

  

    
                store = obj.session.createRawPixelsStore(); 

                imageList = dataset.linkedImageList;
                %       
                if 0==imageList.size()
                    errordlg(['Dataset ' pName ' have no images'])
                    return;
                end;                                    
                %        
                NoOfFiles = imageList.size();
                h = []; %sizeX
                w = []; %sizeY
                im = [];                                
                for k = 1:NoOfFiles,                                           
                           image = imageList.get(k-1);
                           pixelsList = image.copyPixels();    
                           pixels = pixelsList.get(0);
                           pixelsId = pixels.getId().getValue();
                           store.setPixelsId(pixelsId, false);                                           
                           %
                           if isempty(h) % only once, to initialize
                                sizeX = pixels.getSizeX().getValue();
                                sizeY = pixels.getSizeY().getValue();
                                sizeZ = pixels.getSizeZ().getValue();
                                sizeC = pixels.getSizeC().getValue();
                                if 1~=sizeZ || 1~=sizeC
                                    errordlg('wrong image size'); return;
                                end                                
                                h = sizeX;
                                w = sizeY;
                                im = zeros(w,h);
                           end
                           %
                         rawPlane = store.getPlane(0, 0, 0);   
                         plane = toMatrix(rawPlane, pixels); 
                         im = im + double(plane');                                                                                                        
                end
                %
                im = im / NoOfFiles;
   
                store.close();
                
    % correct for labview broken tiffs
    if all(im > 2^15)
        im = im - 2^15;
    end
            
    %{
    extent = 3;
    kernel1 = ones([extent 1]) / extent;
    kernel2 = ones([1 extent]) / extent;
    
    filtered = conv2nan(im,kernel1);                
    im = conv2nan(filtered,kernel2); 
    %}
    
    extent = 3;
    im = medfilt2(im,[extent extent], 'symmetric');
        
    if any(size(im) ~= [data_series.height data_series.width])
        throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
    else
        data_series.background_image = im;
        data_series.background_type = 2;
    end    

    data_series.compute_tr_data();
    
end