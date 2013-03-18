function data_cube = get_FLIM_cube( session, image, sizet , modulo, ZCT )



    % sizet  here is the size of the relative-time dimension(t)
    % ie the number of time-points/length(delays)
     %
    data_cube = [];
    %
    if ~strcmp(modulo,'ModuloAlongC') && ~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
        [ST,I] = dbstack('-completenames');
        errordlg(['No acceptable ModuloAlong* in the function ' ST.name]);
        return;
    end;    
    
    
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
    %
    sizeX = pixels.getSizeX().getValue();
    sizeY = pixels.getSizeY().getValue();
    %sizeC = pixels.getSizeC().getValue();
    %sizeT = pixels.getSizeT().getValue();
    %sizeZ = pixels.getSizeZ().getValue();
    %
    pixelsId = pixels.getId().getValue();
   
    store = session.createRawPixelsStore(); 
    store.setPixelsId(pixelsId, false);  
    
    w = waitbar(0, 'Loading FLIMage....');
    drawnow;
    
    % convert to java/c++ numbering from 0
    Z  = ZCT(1)-1;
    C = ZCT(2)-1;
    T = ZCT(3)-1;
    
    data_cube = zeros(sizet,1,sizeY,sizeX,1);
    
    
    
     tStart = tic; 
     
     barstep = 1;
     
     if sizet > 16 
         barstep = 4;
     end;
     
      if sizet > 64
         barstep = 16;
     end;
     
     barctr = 0;
    
    switch modulo
        case 'ModuloAlongZ'
            tt = Z .* sizet;
            for t = 1:sizet
                rawPlane = store.getPlane(tt , C, T ); 
                tt = tt + 1;
                plane = toMatrix(rawPlane, pixels); 
                data_cube(t,1,:,:,1) = plane';
                barctr = barctr + 1;
                if barctr == barstep
                    waitbar((t/sizet),w);
                    barctr = 0;
                    drawnow;
                end
                
            end
            
        case 'ModuloAlongC' 
            tt = C .* sizet;
            for t = 1:sizet
                rawPlane = store.getPlane(Z , tt, T ); 
                tt = tt + 1;
                plane = toMatrix(rawPlane, pixels); 
                data_cube(t,1,:,:,1) = plane';
                barctr = barctr + 1;
                if barctr == barstep
                    waitbar((t/sizet),w);
                    barctr = 0;
                    drawnow;
                end
            end
            
        case 'ModuloAlongT' 
            tt = T .* sizet;
            for t = 1:sizet
                rawPlane = store.getPlane(Z , C, tt); 
                tt = tt + 1;
                plane = toMatrix(rawPlane, pixels); 
                data_cube(t,1,:,:,1) = plane';
                barctr = barctr + 1;
                if barctr == barstep
                    waitbar((t/sizet),w);
                    barctr = 0;
                    drawnow;
                end
                
            end
            
    end
    
     tElapsed = toc(tStart)
    
    

    delete(w);
    drawnow;
    
    store.close();

end

