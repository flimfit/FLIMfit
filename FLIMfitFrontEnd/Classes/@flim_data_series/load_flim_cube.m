
function[success] = load_flim_cube(obj, file, selected)


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
    
    nchans = length(Carr);
    
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


        switch ext

            % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % No need to allow for multiple Z,C or T as this format can't store them
            case '.tif'
                
               
                dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
                
                if length(dirStruct) ~= sizet
                    success = false
                    return;
                end

                for t = 1:sizet

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
                        obj.data_series_mem(t,1,:,:,selected) = plane;
                    catch error
                        throw(error);
                    end

                end
                
                if min(obj.data_series_mem(:,1,:,:,selected)) > 32500
                    obj.data_series_mem(:,1,:,:,selected) = obj.data_series_mem(:,1,:,:,selected) - 32768;    % clear the sign bit which is set by labview
                end

                


                % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {'.sdt','.msr','.ome', '.ics'}
                
                
                
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
                        
                        if ~sgn     % unsigned data
                            
                            switch modulo
                                case 'ModuloAlongT'
                                    T = T * sizet;
                                    for t = 0:sizet -1
                                        % this is the loop that needs to be
                                        % optimised for speed
                                        index = r.getIndex(Z, chan ,T + t);
                                        rawPlane = r.openBytes(index);
                                        I = loci.common.DataTools.makeDataArray(rawPlane,bpp, fp, little);
                                        I = typecast(I,type);
                                        obj.data_series_mem(t +1,pctr,:,:,selected) = reshape(I, sizeX, sizeY)';
                                    end
                                    
                                case 'ModuloAlongZ'
                                    Z = Z * sizet;
                                    for t = 0:sizet -1
                                        index = r.getIndex(Z + t, chan ,T);
                                        plane = bfGetPlane(r,index + 1);
                                        obj.data_series_mem(t+1,pctr,:,:,selected) = plane;
                                    end
                                    
                                case 'ModuloAlongC'
                                    C = chan * sizet;
                                   
                                    im = zeros(128); 
                                   
                                    half = 1;
                                    line = 1;
                                    for t = 0:sizet -1
                                        index = r.getIndex(Z, C + t ,T);
                                        plane = bfGetPlane(r,index + 1);
                                        %obj.data_series_mem(t+1,pctr,:,:,selected) = plane;
                                        
                                        plane = reshape(plane,64,256);
                                        points = sum(plane,2);
                                        if half ==1
                                            im(1:64,line) = points;
                                            half = 2;
                                        else
                                            im(65:128,line) = points;
                                            half = 1;
                                            line = line +1;
                                        end
                                        
                                        
                                        %obj.data_series_mem(:,pctr,t+1,:,selected) = plane;
                                        
                                    end
                                    
                                    disp('printing')
                                    
                                    imagesc(im);
                                    
                                    dbgstop;
                                   
                                   
                                    
                                    
                            end  % end switch
                            
                            % signed data. Rarely  used so no attempt to optimise
                        else
                            
                            switch modulo
                                case 'ModuloAlongT'
                                    T = T * sizet;
                                    for t = 0:sizet -1
                                        index = r.getIndex(Z, chan ,T + t);
                                        plane = bfGetPlane(r,index + 1);
                                        obj.data_series_mem(t +1,pctr,:,:,selected) = plane;
                                    end
                                    
                                case 'ModuloAlongZ'
                                    Z = Z * sizet;
                                    for t = 0:sizet -1
                                        index = r.getIndex(Z + t, chan ,T);
                                        plane = bfGetPlane(r,index + 1);
                                        obj.data_series_mem(t+1,pctr,:,:,selected) = plane;
                                    end
                                    
                                    
                                case 'ModuloAlongC'
                                    C = chan * sizet
                                    for t = 0:sizet -1
                                        index = r.getIndex(Z, C + t ,T);
                                        plane = bfGetPlane(r,index + 1);
                                        obj.data_series_mem(t+1,pctr,:,:,selected) = plane;
                                    end
                                    
                                    
                            end  % end switch
                            
                        end     % end signed/unsigned
                    end     % end if selected
                        
                        
                    if polarisation_resolved
                        pctr = pctr + 1;
                    else
                        ctr = ctr + 1;
                    end
                        
                end     % nchans
                
                
                % DEBUG timing
                tElapsed = toc(tstart)
                
                
                %Bodge to suppress bright line artefact on RHS in BH .sdt files
                if strfind(file,'.sdt')
                    obj.data_series_mem(:,:,:,end,:) = 0;
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
                          obj.data_series_mem(:,pctr,:,:,selected) = ir(:,chan); 
                    end
                         
                   if polarisation_resolved
                        pctr = pctr + 1;
                   else
                        ctr = ctr + 1;
                   end
                         
                end
                
                
                

            % more txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {'.asc', '.irf'}

                block = 1;       % deprecated retained for compatibility with old load_flim_files
                
                for c = 1:nchans
                    chan = Carr(c) +1;
                   
                    % check that we are supposed to load this FLIM cube 
                    if ctr == selected  ||  polarisation_resolved  || nfiles >1 
                  
                        [delays,data_cube,t_int] = load_flim_file(file, chan,block);
                         obj.data_series_mem(:,pctr,:,:,selected) = data_cube;
                    end
                         
                   if polarisation_resolved
                        pctr = pctr + 1;
                   else
                        ctr = ctr + 1;
                   end
                         
                end
                        
  


        end         % end switch



 
    