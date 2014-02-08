
function[success, target] = load_flim_cube(obj, target, file, selected)


%  Loads FLIM_data from a file or set of files
% The underlying assumption is that if there is more than one name in
% obj.file_names then all the required  planes in that file are to be loaded
% If there is only one filename by contrast then only the selected planes
% are to be loaded.


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
    
    
    
    success = true; 
    
    delays = obj.t;
    sizet = length(delays);
    
    
    sizeX = obj.data_size(3);
    sizeY = obj.data_size(4);
    
    % convert to java/c++ numbering from 0
    Zarr  = obj.ZCT{1}-1;
    Carr = obj.ZCT{2}-1;
    Tarr = obj.ZCT{3}-1;
    
    nfiles = length(obj.file_names);
    
    nZ = length(Zarr);
    nchans = length(Carr);
    nT = length(Tarr);
   
    
    polarisation_resolved =  obj.polarisation_resolved;
    
   
    ctr = 1;       %  Count of FLIM_cubes loaded so far
    pctr = 1;       % polarised counter (should only go up to 2)
    
    
    [path,fname,ext] = fileparts(file);
    
    
    if strcmp(ext,'.tiff')
        ext = '.tif';
    end
    
    if strcmp(ext,'.tif')
        if length(fname) > 5 && strcmp(fname(end-3:end),'.ome')
            ext = '.ome';
        end
    end
    
    
    % default do not display a waitbar
    nblocks = 1;
    nplanesInBlock = sizet;
    verbose = false;
    
    % display a wait bar when required
    if nfiles == 1  && length(obj.names) == 1 
        
        verbose = true;
      
        
        if polarisation_resolved
            totalPlanes = sizet * 2;
        else
            
            totalPlanes = sizet;
       
            % ideally load data in 4 block
            nblocks = 4;

            if sizet < 4
                nblocks = 1;
            end

            number_planes = round(totalPlanes/nblocks);
            nplanesInBlock = ones(1,nblocks) .* number_planes;

            overshoot = squeeze(sum(nplanesInBlock)) - sizet;

            nplanesInBlock(end) = nplanesInBlock(end) - overshoot;
            if nplanesInBlock(end) == 0;
                nplanesInBlock = nplanesInBlock(1:end -1);
                nblocks = nblocks - 1;
            end
        end
        
        totalPlane = 1;

    end
    
   
    
    
    
    
    switch ext
        
        % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % No need to allow for multiple Z,C or T as this format can't store them
        case '.tif'
            
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end
            
            dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
            
            if length(dirStruct) ~= sizet
                success = false
                return;
            end
            
            t = 1;
            for block = 0:nblocks - 1
                
                nplanes = nplanesInBlock(block + 1);
                
                for p = 1:nplanes
                    
                    % find the filename which matches the first delay
                    str = num2str(delays(t));
                    ff = 1;
                    while isempty(strfind(dirStruct(ff).name, str))
                        ff = ff + 1;
                        if ff > sizet
                            success = false;
                            return;
                        end
                    end
                    
                    filename = [path filesep dirStruct(ff).name];
                    
                    try
                        plane = imread(filename,'tif');
                        target(t,1,:,:,selected) = plane;
                    catch error
                        throw(error);
                    end
                    
                    t = t +1;
                    
                end
                
                if verbose
                    totalPlane = totalPlane + nplanes;
                    waitbar(totalPlane /totalPlanes,w);
                    drawnow;
                end
                
            end
            
            if min(target(:,1,:,:,selected)) > 32500
                target(:,1,:,:,selected) = target(:,1,:,:,selected) - 32768;    % clear the sign bit which is set by labview
            end
            
            if verbose
                delete(w);
                drawnow;
            end
            
            
            % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case {'.sdt','.msr','.ome', '.ics'}
           
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end
            
            % bio-Formats should already be loaded by
            % get_image_dimensions
            
            % if this is the same file from which we got the image
            % dimensions
            if strcmp(file,obj.file_names(1) )  && ~isempty(obj.bfReader)
                r = obj.bfReader;
                omeMeta = obj.bfOmeMeta;
            else
                % Toggle the stitchFiles flag to control grouping of similarly
                % named files into a single dataset based on file numbering.
                stitchFiles = 0;
                
                % Get the channel filler
                disp('starting a new reader')
                r = bfGetReader(file, stitchFiles);
                omeMeta = r.getMetadataStore();
                r.setSeries(obj.block - 1);
                
            end
            
            
            if strcmp(ext,'.sdt')
                % burrow down through all the bio-formats wrappers to
                % get to the SDTReader class
                r.unwrap.setPreLoad(true);      % switch on pre-loading    
            end
            
            
            %check that image dimensions match those read from first
            %file
            
            block = obj.block;
            
            
            if sizeX ~= r.getSizeX ||sizeY ~= r.getSizeY
                success = false;
                return;
            end
            
            
            modulo = obj.modulo;
            
            % timing debug
            tstart = tic;
            
            
            
            % Get pixel type
            pixelType = r.getPixelType();
            bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
            fp = loci.formats.FormatTools.isFloatingPoint(pixelType);
            sgn = loci.formats.FormatTools.isSigned(pixelType);
            % asume for now all our data is unsigned (see bfgetPlane for examples of signed)
            little = r.isLittleEndian();
            
            switch bpp
                case 1
                    type = 'uint8';
                case 2
                    type = 'uint16';
                case 4
                    type = 'uint32';
                case 8
                    type = 'uint64';
            end
            
            
            
            % TBD add loops for Z & T. For the time being just assume
            % only C > 1
            
            Z = Zarr(1);
            T = Tarr(1);
            
            
            for c = 1:nchans
                chan = Carr(c);
                
                % check that we are supposed to load this FLIM cube
                if ctr == selected  ||  polarisation_resolved  || nfiles >1
                    
                    t = 0;
                    for block = 0:nblocks - 1
                        nplanes = nplanesInBlock(block + 1);
                        
                        switch modulo
                            case 'ModuloAlongT'
                                T = T * sizet;
                                if ~sgn
                                    for p = 1:nplanes
                                        % unsigned moduloAlongT
                                        % this is the loop that needs to be
                                        % optimised for speed
                                       
                                        index = r.getIndex(Z, chan ,T + t);
                                        t = t + 1;
                                        rawPlane = r.openBytes(index);
                                        I = loci.common.DataTools.makeDataArray(rawPlane,bpp, fp, little);
                                        I = typecast(I,type);
                                        target(t,pctr,:,:,selected) = reshape(I, sizeX, sizeY)';
                                    end
                                else  % signed
                                    for p = 1:nplanes
                                        index = r.getIndex(Z, chan ,T + t);
                                        t = t + 1;
                                        plane = bfGetPlane(r,index + 1);
                                        target(t,pctr,:,:,selected) = plane;
                                    end
                                end
                                
                            case 'ModuloAlongZ'
                                Z = Z * sizet;
                                for p = 1:nplanes
                                    index = r.getIndex(Z + t, chan ,T);
                                    t = t + 1;
                                    plane = bfGetPlane(r,index + 1);
                                    target(t,pctr,:,:,selected) = plane;
                                end
                                
                            case 'ModuloAlongC'
                                C = chan * sizet;
                                for p = 1:nplanes
                                    index = r.getIndex(Z, C + t ,T);
                                    t = t + 1;
                                    plane = bfGetPlane(r,index + 1);
                                    target(t,pctr,:,:,selected) = plane;
                                end
                                
                        end  % end switch
                  
                    
                        if verbose
                            totalPlane = totalPlane + nplanes;
                            waitbar(totalPlane /totalPlanes,w);
                            drawnow;
                        end

                    end    % end nblocks
                end     % end if selected

                if polarisation_resolved
                    pctr = pctr + 1;
                else
                    ctr = ctr + 1;
                end

            end     % nchans

            % DEBUG timing
            tElapsed = toc(tstart)

            if verbose
                delete(w);
                drawnow;
            end



            %Bodge to suppress bright line artefact on RHS in BH .sdt files
            if strfind(file,'.sdt')
                target(:,:,:,end,:) = 0;
            end
    
    
            
        % single pixel txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case {'.csv','.txt'}
            
            % if this is the same file from which we got the image
            % dimensions
            if strcmp(file,obj.file_names(1) )  && ~isempty(obj.txtInfoRead)
                ir = obj.txtInfoRead;
            else
                % decode the header & load the data
                
                header_data = obj.parse_csv_txt_header(file);
                if isempty(header_data)
                    success = false;
                    return;
                end
                n_header_lines = length(header_data);
                ir = dlmread(file,dlm,n_header_lines,0);
            end
            
            for c = 1:nchans
                chan = Carr(c) +2;
                
                % check that we are supposed to load this FLIM cube
                if ctr == selected  ||  polarisation_resolved  || nfiles >1
                    target(:,pctr,:,:,selected) = ir(:,chan);
                end
                
                if polarisation_resolved
                    pctr = pctr + 1;
                else
                    ctr = ctr + 1;
                end
                
            end
            
            
            
            
         % more txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case {'.asc'}
            
            block = 1;       % deprecated retained for compatibility with old load_flim_files
            
            for c = 1:nchans
                chan = Carr(c) +1;
                
                % check that we are supposed to load this FLIM cube
                if ctr == selected  ||  polarisation_resolved  || nfiles >1
                    
                    [delays,data_cube,t_int] = load_flim_file(file, chan,block);
                    target(:,pctr,:,:,selected) = data_cube;
                end
                
                if polarisation_resolved
                    pctr = pctr + 1;
                else
                    ctr = ctr + 1;
                end
                
            end
            
          case {'.irf'}
              
            % if this is the same file from which we got the image
            % dimensions
            if strcmp(file,obj.file_names(1) )  && ~isempty(obj.txtInfoRead)
                ir = obj.txtInfoRead;
            else
                ir = load(file);
            end
            
            % this format can ony hold 1 channel
            target(:,pctr,:,:,selected) = ir(:,2);
           
            if polarisation_resolved
                pctr = pctr + 1;
            else
                ctr = ctr + 1;
            end
            
            
            
            
            
    end         % end switch
    
    
    
    
    