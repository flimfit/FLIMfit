
function data_cube = get_FLIM_cube_Channels( session, imgId, modulo, ZCT )
    %
    data_cube = [];
    %
    if ~strcmp(~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
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
    if 
    %   
    switch modulo
        case 'ModuloAlongZ' 
            N = sizeZ;        
        case 'ModuloAlongT' 
            N = sizeT;        
    end    
    %
    pixelsId = pixels.getId().getValue();
    image.getName().getValue();
        store = session.createRawPixelsStore(); 
        store.setPixelsId(pixelsId, false);    
    % 
    data_cube = zeros(N, sizeY, sizeX);            
    %
    Z = ZCT(1)-1;
    C = ZCT(2)-1;
    T = ZCT(3)-1;
    %    
    for k = 1:N,
        switch modulo % getPlane(Z,C,T)
            case 'ModuloAlongZ' 
                rawPlane = store.getPlane(k - 1, C, T );        
            case 'ModuloAlongT' 
                rawPlane = store.getPlane(Z, C, k - 1);        
        end
        %
        plane = toMatrix(rawPlane, pixels); 
        data_cube(k,:,:) = plane';
    end

    store.close();

end

