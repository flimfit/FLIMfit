function data_cube = get_FLIM_cube( session, image, sizet , modulo, ZCT , verbose)

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
   
    
    
     % convert to java/c++ numbering from 0
    Zarr  = ZCT{1}-1;
    Carr = double(ZCT{2}-1);
    Tarr = ZCT{3}-1;
    
    
     nchans = length(Carr);
    
    if length(Zarr) > 1 || length(Tarr) > 1   ||  nchans > 2    % temporarily only allow C to be non-singular
        return;
    end
    
    
    
    if verbose
    
        w = waitbar(0, 'Loading FLIMage....');
        drawnow;
        totalPlanes = sizet * nchans;
        
        % ideally load data in 4 block
         nblocks = 4;
        
         if sizet < 4
            nblocks = 1;
         end
            
           
         number_planes = round(sizet/nblocks);
         nplanesInBlock = ones(1,nblocks) .* number_planes;

         overshoot = squeeze(sum(nplanesInBlock)) - sizet;

         nplanesInBlock(end) = nplanesInBlock(end) - overshoot;
         if nplanesInBlock(end) == 0;
            nplanesInBlock = nplanesInBlock(1:end -1);
         end
        
        
         
         
    else        % not verbose
        
        
        %when not displaying 
        % just use one block
        nblocks = 1;
        nplanesInBlock = sizet;
       
    
    end  % not verbose
    
    
   
   
    store = session.createRawPixelsStore(); 
    store.setPixelsId(pixelsId, false); 
    
    % returns type double
    data_cube = zeros(sizet,nchans,sizeY,sizeX,1);
    
    
     
      % Cast the binary data into the appropriate format
    type = char(pixels.getPixelsType().getValue().getValue());
    if strcmp(type,'float')
         type = 'single';
    end
    
    Z = Zarr(1);
    T = Tarr(1);
    
   
    
     % offset values in each dimension XYZCT
     offset = java.util.ArrayList;
     offset.add(java.lang.Integer(0));
     offset.add(java.lang.Integer(0));
     offset.add(java.lang.Integer(0));
     offset.add(java.lang.Integer(0));
     offset.add(java.lang.Integer(0));
        
    siz = java.util.ArrayList;      % by default load one plane at a time
    siz.add(java.lang.Integer(sizeX));
    siz.add(java.lang.Integer(sizeY));
    siz.add(java.lang.Integer(1));      % sizeZ
    siz.add(java.lang.Integer(1));   %sizeC load 
    siz.add(java.lang.Integer(1));   %sizeT
    
    % indicate the step in each direction, step = 1, will return values at index 0, 1, 2.
    % step = 2, values at index 0, 2, 4 etc.
    step = java.util.ArrayList;
    step.add(java.lang.Integer(1));
    step.add(java.lang.Integer(1));
    step.add(java.lang.Integer(1));
    step.add(java.lang.Integer(1));
    step.add(java.lang.Integer(1));

    
   
        
    
   
 
    imSize = sizeX * sizeY;
    
    for c = 1:nchans
        
        C = Carr(c);
        offset.set(3,java.lang.Integer(C)); % set channel offset
        
         switch modulo
            case 'ModuloAlongZ'
                tt = Z .* sizet;
                modNo = 2;
            case 'ModuloAlongC' 
                tt = C .* sizet; 
                modNo = 3;
            case 'ModuloAlongT' 
                tt = T .* sizet; 
                modNo = 4;
         end
        
        
         
       
        t = 1;
        
        for block = 0:nblocks - 1
            
            nplanes = nplanesInBlock(block + 1);
            
            
            siz.set(modNo,java.lang.Integer(nplanes));
             source = tt + ( t - 1);
             offset.set(modNo,java.lang.Integer(source));
            
        
            rawCube = store.getHypercube(offset, siz, step);

            cube = typecast(rawCube, type);
            
           
            for p = 1:nplanes  
                
                 %following 3 lines replace 'plane = toMatrix(rawPlane, pixels);'
                %for speed
                
                plane = cube(((p -1)*imSize)+ 1: (p * imSize));
                plane = reshape(plane, sizeX, sizeY);
                plane  = swapbytes(plane);
                
                data_cube(t,c,:,:,1) = plane';
                t = t + 1;
            end
            
           
            
            if verbose
                waitbar((t*c) /totalPlanes,w);
                drawnow;
            end
           

        end

           
    end % end for nchans

     
    
    store.close();
    
    if verbose
        delete(w);
        drawnow;
    end

end

