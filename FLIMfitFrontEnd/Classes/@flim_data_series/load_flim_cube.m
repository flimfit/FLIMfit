
function[success, target] = load_flim_cube(obj, target, file, read_selected, write_selected, reader_settings, dims, ZCT)

    %  Loads FLIM_data from a file or set of files


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
        no_mix = true;   
    else
        delays = dims.delays;
        nfiles = 1;   % only a single file except for the data
        sizet = length(dims.delays);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        modulo = dims.modulo;
        % allow file types bio-formats cannot recognise to be mixed 
        % with those it can for irfs etc
        no_mix = false;
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
    
    
    % bio-Formats should already be loaded by
    % get_image_dimensions
    % if this is the same file from which we got the image
    % dimensions
    if strcmp(file,obj.file_names(1) )  && ~isempty(obj.bfReader)
        r = obj.bfReader;
        omeMeta = obj.bfOmeMeta;
        ext = '.bio';
    else
        [ext,r] = obj.init_bfreader(file);
        % if first file was bio-formats readable then all others must be
        % unless no_mix flag specifically allows for irfs
        if ~isempty(obj.bfReader)
            if ~strcmp(ext,'.bio') && no_mix
                success = false;
                return;
            end
        end
            
    end
    
     
    % default do not display a waitbar. So no need for mutiple blocks
    nblocks = 1;
    nplanesInBlock = sizet;
    verbose = false;
    
    % display a wait bar when required
    if (nfiles == 1 && obj.load_multiple_planes == 0 ) || obj.lazy_loading  
        
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
        
         % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case '.bio'
           
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end
             
            if length(obj.imageSeries) >1   % if imageSeries is a vector indicates a plate
                r.setSeries(obj.imageSeries(read_selected) - 1);
                read_selected= 1;
            else
                r.setSeries(obj.imageSeries -1);
            end
               
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
            % assume for now all our data is unsigned (see bfgetPlane for examples of signed)
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
                        if ctr == read_selected  ||  polarisation_resolved 
                          
                            t = 0;
                            for block = 0:nblocks - 1
                                nplanes = nplanesInBlock(block + 1);
                                
                                switch modulo
                                    case 'ModuloAlongT'
                                        Tt = T * sizet;
                                        if ~sgn
                                            for p = 1:nplanes
                                                % unsigned moduloAlongT
                                                % this is the loop that needs to be
                                                % optimised for speed
                                                index = r.getIndex(Z, chan ,Tt + t);
                                                t = t + 1;
                                                rawPlane = r.openBytes(index);
                                                I = loci.common.DataTools.makeDataArray(rawPlane,bpp, fp, little);
                                                I = typecast(I, type);
                                                target(t,pctr,:,:,write_selected) = reshape(I, sizeY, sizeX)';
                                                
                                            end
                                        else  % signed
                                            for p = 1:nplanes
                                                index = r.getIndex(Z, chan ,Tt + t);
                                                t = t + 1;
                                                plane = bfGetPlane(r,index + 1);
                                                target(t,pctr,:,:,write_selected) = plane;
                                            end
                                        end
                                        
                                    case 'ModuloAlongZ'
                                        Zt = Z * sizet;
                                        for p = 1:nplanes
                                            index = r.getIndex(Zt + t, chan ,T);
                                            t = t + 1;
                                            plane = bfGetPlane(r,index + 1);
                                            target(t,pctr,:,:,write_selected) = plane;
                                        end
                                        
                                    case 'ModuloAlongC'
                                        Ct = chan * sizet;
                                        for p = 1:nplanes
                                            index = r.getIndex(Z, Ct + t ,T);
                                            t = t + 1;
                                            plane = bfGetPlane(r,index + 1);
                                            target(t,pctr,:,:,write_selected) = plane;
                                        end
                                        
                                end  % end switch
                                
                                
                                if verbose
                                    totalPlane = totalPlane + nplanes;
                                    waitbar(totalPlane /totalPlanes,w);
                                    drawnow;
                                end
                                
                            end    % end nblocks
                        end     % end if read_selected
                        
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
                
                if strcmp(file(end-3:end),'.sdt')  && sizeX > 1 && sizeY > 1
                    target(:,:,:,end,:) = 0;
                end
                
            else    % Not TCSPC
                if min(target(target > 0)) > 32500
                    target = target - 32768;    % clear the sign bit which is set by labview
                end
            end
            
           

        case {'.pt3', '.ptu', '.bin2', '.ffd'}
            
            r = FLIMreaderMex(file);
            FLIMreaderMex(r,'SetSpatialBinning',reader_settings.spatial_binning);
            FLIMreaderMex(r,'SetNumTemporalBits',reader_settings.num_temporal_bits);
            FLIMreaderMex(r,'SetRealignmentParameters',reader_settings.realignment);

            if ~polarisation_resolved && length(Carr) > 1 
                chan = Carr(read_selected); % load channels sequentially
            else
                chan = Carr;
            end
            
            data = FLIMreaderMex(r, 'GetData', chan);
            
            expected_size = size(target);
            expected_size((length(expected_size)+1):4) = 1;
            actual_size = size(data);
            actual_size((length(actual_size)+1):4) = 1;
            if all(actual_size==expected_size(1:4))        
                target(:,:,:,:,write_selected) = data;
            else
                disp(['File "' file '" was unexpected size']);
            end
            FLIMreaderMex(r,'Delete');
        
        % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % No need to allow for multiple Z,C or T as this format can't store them
        case {'.tif','.tiff'}
                        
            path = fileparts(file);
            dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
            files = {dirStruct.name};
            [~,~,files] = get_delays_from_tif_stack(files);
                        
            if length(files) ~= sizet
                success = false;
                return;
            end
            
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end
            
            for p = 1:sizet
                filename = [path filesep files{p}];
                plane = imread(filename,'tif');
                target(p,1,:,:,write_selected) = plane;
                if verbose
                    waitbar(sizet /p,w);
                    drawnow;
                end
            end
                            
            if min(target(:,1,:,:,write_selected)) > 32500
                target(:,1,:,:,write_selected) = target(:,1,:,:,write_selected) - 32768;    % clear the sign bit which is set by labview
            end
            
            if verbose
                delete(w);
                drawnow;
            end
            
    
            
        % single pixel txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                if ctr == read_selected  ||  polarisation_resolved  
                    target(:,pctr,:,:,write_selected) = ir(:,chan);
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
                target(:,1,1,1,write_selected) = data;
            else
                target(:,1,:,:,write_selected) = data;
            end
          
          case {'.irf'}
              
            % if this is the same file from which we got the image
            % dimensions
               
            if  ~isempty(obj.file_names) & strcmp(file,obj.file_names(1) )  & ~isempty(obj.txtInfoRead)
                ir = obj.txtInfoRead;
            else
                ir = load(file);
            end
            
            
            target(:,pctr,:,:,write_selected) = ir(:,2);
           
            if polarisation_resolved
                pctr = pctr + 1;
            else
                ctr = ctr + 1;
            end
            
            
            
            
            
    end         % end switch
    
  
    
    
    
    
    