function[success, target] = load_flim_cube(obj, target, image, read_selected, write_selected, reader_settings, dims, ZCT)

    % Loads FLIM_data from an OMERO image or set of images

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
    
    if nargin < 6
        reader_settings = obj.reader_settings;
    end
    
    if nargin < 7        % dims/ZCT have not  been passed so get dimensions from data_series obj
        delays = obj.t;
        sizet = length(delays);
        nfiles = length(obj.file_names);
        sizeX = obj.data_size(3);
        sizeY = obj.data_size(4);
        ZCT = obj.ZCT;
        modulo = obj.modulo;
    else
        % if image is in fact a filename then call the superclass method
        % instead
        if strfind(class(image),'char')
            [success, target] = load_flim_cube@flim_data_series(obj, target, image, read_selected, write_selected, reader_settings, dims, ZCT);
            return;
        end
        
        nfiles = 1;  % only 1 file except for the data
        sizet = length(dims.delays);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        modulo = dims.modulo;
    end
    
    success = true;
    
    if strcmp(modulo,'none')
        sizet = 1;
    end
    
    
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
    if (nfiles == 1 && obj.load_multiple_planes == 0 ) || obj.lazy_loading
        
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
        
        verbose = false;
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
    session = obj.omero_logon_manager.session;
    pixelsList = image.copyPixels();
    pixels = pixelsList.get(0);
    
    pixelsId = pixels.getId().getValue();
    
    
    
    if sizeX.* sizeY  ~= pixels.getSizeX.getValue * pixels.getSizeY.getValue
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
    
    for zplane = 1:nZ
        Z = Zarr(zplane);
        
        for c = 1:nchans
            chan = Carr(c);
            
            for time = 1:nT
                T = Tarr(time);
                
                
                
                
                % check that we are supposed to load this FLIM cube
                if ctr == read_selected || polarisation_resolved
                    
                    t = 0;
                    
                    offset.set(2,java.lang.Integer(Z)); % set Z offset
                    offset.set(3,java.lang.Integer(chan)); % set channel offset
                    offset.set(4,java.lang.Integer(T)); % set T offset
                    
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
                        otherwise      % not time-resolved
                            tt = T;
                            modNo = 4;  % default to T
                            
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
                            
                            
                            target(t,pctr,:,:,write_selected) = plane';
                            
                        end
                        
                        if verbose
                            
                            totalPlane = totalPlane + nplanes;
                            waitbar(totalPlane /totalPlanes,w);
                            drawnow;
                        end
                    end   % end nblocks
                end   % end if read_selected
                
                if polarisation_resolved
                    pctr = pctr + 1;
                else
                    ctr = ctr + 1;
                end
            end
        end % end nchans
    end
    
    
    store.close();
    
  
    if strcmp('TCSPC',obj.mode)
        %Kludge to suppress bright line artefact on RHS in BH .sdt files
        file = char(image.getName().getValue());
        if strcmp(file(end-3:end),'.sdt')  && sizeX > 1 && sizeY > 1
            target(:,:,:,end,:) = 0;
        end
        
    else    % Not TCSPC
        if min(target(target > 0)) > 32500
            target = target - 32768;    % clear the sign bit which is set by labview
        end
    end
    
     if verbose
        delete(w);
        drawnow;
    end
    
    
    
    
end


