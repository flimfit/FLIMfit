function[success, target] = load_flim_cube(obj, target, image, selected, dims, ZCT)

%  Loads FLIM_data from an OMERO image or set of images
% The underlying assumption is that if there is more than one name in
% obj.file_names then all the required  planes in that file are to be loaded
% If there is only one filename by contrast then only the selected planes
% are to be loaded.


    if nargin < 6        % dims/ZCT have not  been passed so get dimensions from data_series obj
        delays = obj.t;
        sizet = length(delays);
        nfiles = length(obj.file_names);
        sizeX = obj.data_size(3);
        sizeY = obj.data_size(4);
        ZCT = obj.ZCT;
        total_files = length(obj.names);
        modulo = obj.modulo;
    else
        nfiles = length(selected);
        sizet = length(dims.delays);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        total_files = nfiles;
        modulo = dims.modulo;
    end
    
    success = true; 
    
    
    % convert to java/c++ numbering from 0
    Zarr  = ZCT{1}-1;
    Carr = ZCT{2}-1;
    Tarr = ZCT{3}-1;
    
   
    nZ = length(Zarr);
    nchans = length(Carr);
    nT = length(Tarr);
   
    
    polarisation_resolved =  obj.polarisation_resolved;
    
   
    ctr = 1;       %  Count of FLIM_cubes loaded so far
    pctr = 1;       % polarised counter (should only go up to 2)
    
     % display a wait bar when required
    if nfiles == 1  && total_files == 1 
        verbose = true;
   
        w = waitbar(0, 'Loading FLIMage....');
        drawnow;
        totalPlanes = sizet * nchans;
        
         if sizet < 4
            nblocks = 1;
            nplanesInBlock = sizet;
         else
             % ideally load data in 4 blocks
            nblocks = 4; 
         end
            
     
         
    else        % not verbose

        
        %when not displaying 
        % just use one block unless there are a huge no of planes
        if sizet < 400
            nblocks = 1;
            nplanesInBlock = sizet;
        else
            nblocks = 4;
        end

 
    end  % not verbose

    % multi-block download
    if nblocks == 4

        number_planes = round(sizet/nblocks);
        nplanesInBlock = ones(1,nblocks) .* number_planes;

        overshoot = squeeze(sum(nplanesInBlock)) - sizet;

        nplanesInBlock(end) = nplanesInBlock(end) - overshoot;

        if nplanesInBlock(end) == 0;
            nplanesInBlock = nplanesInBlock(1:end -1);
            nblocks = nblocks - 1;
        end


    end
    
     % No requirement for looking at series_count as OMERO stores each block
    % as a separate image
    session = obj.omero_data_manager.session;
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
    
    pixelsId = pixels.getId().getValue();
    
    
 
    if sizeX .* sizeY  ~= pixels.getSizeX.getValue * pixels.getSizeY.getValue
        success = false;
        return;
    end
    
    
   
    store = session.createRawPixelsStore();
    store.setPixelsId(pixelsId, false); 
    
     
      % Cast the binary data into the appropriate format
    type = char(pixels.getPixelsType().getValue().getValue());
    if strcmp(type,'float')
         type = 'single';
    end
    
     % TBD add loops for Z & T. For the time being just assume
    % only C > 1
    
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
    siz.add(java.lang.Integer(sizeY));
    siz.add(java.lang.Integer(sizeX));
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

    totalPlane = 1;
 
    imSize = sizeX * sizeY;
    
    for c = 1:nchans
        
        chan = Carr(c);
        
        % check that we are supposed to load this FLIM cube
        if ctr == selected || polaristion_resolved || nfiles > 1
            
            t = 0;
            offset.set(3,java.lang.Integer(chan)); % set channel offset

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
        
   
            for block = 0:nblocks - 1
                nplanes = nplanesInBlock(block + 1);
            
                siz.set(modNo,java.lang.Integer(nplanes));
                source = tt + t;
                offset.set(modNo,java.lang.Integer(source));
            
        
                rawCube = store.getHypercube(offset, siz, step);

                cube = typecast(rawCube, type);
            
           
                for p = 1:nplanes  
                
                    %following 3 lines replace 'plane = toMatrix(rawPlane, pixels);'
                    %for speed

                    plane = cube(((p -1)*imSize)+ 1: (p * imSize));
                    plane = reshape(plane, sizeY, sizeX);
                    plane  = swapbytes(plane);

                    t = t + 1;
                   
                
                    target(t,pctr,:,:,selected) = plane';                 
                
                end
            
                if verbose

                    totalPlane = totalPlane + nplanes;
                    waitbar(totalPlane /totalPlanes,w);
                    drawnow;
                end
            end   % end nblocks
        end   % end if selected
        
        if polarisation_resolved
            pctr = pctr + 1;
        else
            ctr = ctr + 1;
        end
      
    end % end nchans

    
    
    store.close();
    
    if verbose
        delete(w);
        drawnow;
    end
    
    file = char(image.getName().getValue());
    
    %Bodge to suppress bright line artefact on RHS in BH .sdt files
    if strfind(file,'.sdt')
        target(:,:,:,end,:) = 0;
    end

end

    
    