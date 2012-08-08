function data_cube = get_Channels( session, imgId, n_blocks, block )
    %
% %     gateway = session.createGateway();
% %     %
% %     pixels = gateway.getPixelsFromImage(imgId);
% %         pixelsId = pixels.get(0).getId().getValue()
% %             pixels = gateway.getPixels(pixelsId);
% %     %
% %     sizeZ = pixels.getSizeZ().getValue();
% %     sizeT = pixels.getSizeT().getValue();
% %         if 1~= sizeZ || 1~= sizeT
% %             errordlg('no Z-planes, no timepoints expected - can not continue');
% %         end;
% %     %
% %     sizeX = pixels.getSizeX().getValue();
% %     sizeY = pixels.getSizeY().getValue();
% %     sizeC = pixels.getSizeC().getValue();
% %     %    
% %     if 0 == block || isempty(n_blocks) || isempty(block) || n_blocks < block
% %         c_begin = 1;
% %         c_end = sizeC;
% %     else
% %         n_channels = floor(sizeC/n_blocks);
% %         %
% %         c_begin = 1 + n_channels*(block - 1);
% %         c_end = c_begin + n_channels - 1;        
% %     end
% %     %
% %     data_cube = zeros(c_end - c_begin + 1, sizeX, sizeY);            
% %     %
% %     for c = c_begin:c_end,
% %         rawPlane = gateway.getPlane(pixelsId, 0, c - 1, 0);        
% %             plane = toMatrix(rawPlane, pixels);    
% %                 data_cube(c - c_begin + 1,:,:) = plane;
% %     end
% %     %
% %     gateway.close();    

    %
    proxy = session.getContainerService();
    ids = java.util.ArrayList();
    ids.add(java.lang.Long(imgId)); %add the id of the image.
    list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
    if (list.size == 0)
        exception = MException('OMERO:ImageID', 'Image Id not valid');
        throw(exception);
    end
    image = list.get(0);
        pixelsList = image.copyPixels();    
            pixels = pixelsList.get(0);
    %
    sizeZ = pixels.getSizeZ().getValue();
    sizeT = pixels.getSizeT().getValue();
        if 1~= sizeZ || 1~= sizeT
            errordlg('no Z-planes, no timepoints expected - can not continue');
        end;
    %
    sizeX = pixels.getSizeX().getValue()
    sizeY = pixels.getSizeY().getValue()
    sizeC = pixels.getSizeC().getValue()
    %
    pixelsId = pixels.getId().getValue();
    image.getName().getValue()
        store = session.createRawPixelsStore(); 
        store.setPixelsId(pixelsId, false);    
    %    
    if 0 == block || isempty(n_blocks) || isempty(block) || n_blocks < block
        c_begin = 1;
        c_end = sizeC;
    else
        n_channels = floor(sizeC/n_blocks);
        %
        c_begin = 1 + n_channels*(block - 1);
        c_end = c_begin + n_channels - 1;        
    end
    %
    data_cube = zeros(c_end - c_begin + 1, sizeX, sizeY);            
    %
    for c = c_begin:c_end,
        c - 1
        rawPlane = store.getPlane(0, c - 1, 0);        
            plane = toMatrix(rawPlane, pixels);    
                data_cube(c - c_begin + 1,:,:) = plane;
    end
    
    store.close();

end

