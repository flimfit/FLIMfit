
function data_cube = get_FLIM_cube_Channels( session, image, modulo, ZCT )
    %
    data_cube = [];
    %
    if ~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
        [ST,~] = dbstack('-completenames');
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
    w = waitbar(0, 'Loading FLIMage....');
    %
    for k = 1:N,
        switch modulo
            case 'ModuloAlongZ' 
                rawPlane = store.getPlane(k - 1, C, T );        
            case 'ModuloAlongT' 
                rawPlane = store.getPlane(Z, C, k - 1);        
        end
        %
        plane = toMatrix(rawPlane, pixels); 
        data_cube(k,:,:) = plane';
        %
        waitbar(k/N,w);
        drawnow;
        %        
    end

    store.close();

    delete(w);
    drawnow;
    
end

