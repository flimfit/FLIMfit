function load_background_from_Omero_Dataset(obj,session,dataset)
    
                store = session.createRawPixelsStore(); 

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
        
    if any(size(im) ~= [obj.height obj.width])
        throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
    else
        obj.background_image = im;
        obj.background_type = 2;
    end    

    obj.compute_tr_data();
    
end