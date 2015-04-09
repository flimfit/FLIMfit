
function[success, target] = load_flim_cube(obj, target, file, selected, current_image, dims, ZCT)


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
    
   
    if nargin < 7        % dims/ZCT have not  been passed so get dimensions from data_series obj
        delays = obj.t;
        sizet = length(delays);
        nfiles = length(obj.file_names);
        sizeX = obj.data_size(3);
        sizeY = obj.data_size(4);
        ZCT = obj.ZCT;
        total_files = length(obj.names);
        modulo = obj.modulo;
    else
        delays = dims.delays;
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
    
    
    [path,fname,ext] = fileparts_inc_OME(file);
    
    
    % default do not display a waitbar
    nblocks = 1;
    nplanesInBlock = sizet;
    verbose = false;
    
    % display a wait bar when required
    if nfiles == 1  && total_files == 1  || obj.lazy_loading
        
        verbose = true;
      
        
        if polarisation_resolved
            totalPlanes = sizet * 2;
        else
            
            totalPlanes = sizet;
       
            % ideally load data in 4 blocks
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
        case {'.sdt','.msr','.ome', '.ics', '.bin'}
           
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
              
                % Get the channel filler
                r = loci.formats.ChannelFiller();
                r = loci.formats.ChannelSeparator(r);

                OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
                r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());
                r.setId(file);
           
                omeMeta = r.getMetadataStore();
              
            end
            
            
            r.setSeries(obj.imageSeries(current_image) - 1);
            
            
          
            %check that image dimensions match those read from first
            %file
            
            
            % note the dimension inversion here
            if sizeX ~= r.getSizeY ||sizeY ~= r.getSizeX
                success = false;
                return;
            end
         
            
            % timing debug
            %tstart = tic;
          
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
          
            for zplane = 1:nZ
                Z = Zarr(zplane);
                
                for c = 1:nchans
                    chan = Carr(c);
                    
                    for time = 1:nT
                        T = Tarr(time);
                        
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
                                                I = typecast(I, type);
                                                target(t,pctr,:,:,selected) = reshape(I, sizeY, sizeX)';
                                                
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
                        
                    end
                end     % nchans
            end

            % DEBUG timing
           % tElapsed = toc(tstart)

            if verbose
                delete(w);
                drawnow;
            end

            if strcmp('TCSPC',obj.mode)
                
                %Kludge to suppress bright line artefact on RHS in BH .sdt files
                if strcmp(ext,'.sdt')  && sizeX > 1 && sizeY > 1
                    target(:,:,:,end,:) = 0;
                end
                
            else    % Not TCSPC
                if min(target(target > 0)) > 32500
                    target = target - 32768;    % clear the sign bit which is set by labview
                end
            end

        % single pixel txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case '.pt3'
            
            r = FLIMreaderMex(file);
            target(:,:,:,:,selected) = FLIMreaderMex(r, 'GetData', Carr);
            FLIMreaderMex(r,'Delete');
            
        case {'.csv','.txt'}
            
            if strcmp(ext,'.txt')
                 dlm = '\t';
             else
                 dlm = ',';
             end
            
            ir = [];
            
            % if this is the same file from which we got the image
            % dimensions
            if ~isempty(obj.file_names)  && ~isempty(obj.txtInfoRead)
                if strcmp(file,obj.file_names(1) )
                    ir = obj.txtInfoRead;
                end
            end
            
            if isempty(ir)
                % decode the header & load the data
                header_data = obj.parse_csv_txt_header(file);
                if isempty(header_data)
                    n_header_lines = 0;
                else
                    n_header_lines = length(header_data);
                end
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
            
            % if this is the same file from which we got the image
            % dimensions
            if strcmp(file,obj.file_names(1) )  && ~isempty(obj.txtInfoRead)
                data = obj.txtInfoRead;
            else
                [data, delays] = obj.parse_asc_txt(file);
            end
                 
            % this format can't do multi-plane/channel
            if size(data,1) == 1 || size(data,2) == 1
                target(:,1,1,1,selected) = data;
            else
                target(:,1,:,:,selected) = data;
            end
          
          case {'.irf'}
              
            % if this is the same file from which we got the image
            % dimensions
            if strcmp(file,obj.file_names(1) )  && ~isempty(obj.txtInfoRead)
                ir = obj.txtInfoRead;
            else
                ir = load(file);
            end
            
            
            target(:,pctr,:,:,selected) = ir(:,2);
           
            if polarisation_resolved
                pctr = pctr + 1;
            else
                ctr = ctr + 1;
            end
            
            
            
            
            
    end         % end switch
    
  
    
    
    
    
    