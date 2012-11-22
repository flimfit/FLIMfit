function data_cube = get_FLIM_cube( session, imgId, n_blocks, block, modulo, ZCT )
     %
    data_cube = [];
    %
    if ~strcmp(modulo,'ModuloAlongC') && ~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
        [ST,I] = dbstack('-completenames');
        errordlg(['No acceptable ModuloAlong* in the function ' ST.name]);
        return;
    end;    
    %
    proxy = session.getContainerService();
    ids = java.util.ArrayList();
    ids.add(java.lang.Long(imgId)); 
    list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
    if (list.size == 0)
        exception = MException('OMERO:ImageID', 'Image Id not valid');
        throw(exception);
    end
    image = list.get(0);
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
    %    
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
    end

    store.close();

end

