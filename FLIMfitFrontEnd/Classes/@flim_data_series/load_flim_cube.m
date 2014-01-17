
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
    
    Z = obj.ZCT(1);
    C = obj.ZCT(2);
    T = obj.ZCT(3);
    
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
                        
                        obj.data_series_mem(t,1,:,:,selected) = plane';
                    catch error
                        throw(error);
                    end

                end
                
                if min(obj.data_series_mem(:,1,:,:,selected)) > 32500
                    obj.data_series_mem(:,1,:,:,selected) = obj.data_series_mem(:,1,:,:,selected) - 32768;    % clear the sign bit which is set by labview
                end

                


             % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
             case {'.sdt','.msr','.ome'}


                 % bio-Formats should already be loaded by
                 % get_image_dimensions
              
                % Toggle the stitchFiles flag to control grouping of similarly
                % named files into a single dataset based on file numbering.
                stitchFiles = 0;

                % Get the channel filler
                r = bfGetReader(file, stitchFiles);
                
                %check that image dimensions match those read from first
                %file
                omeMeta = r.getMetadataStore();

                if sizeX ~= omeMeta.getPixelsSizeX(0).getValue() ||sizeY ~= omeMeta.getPixelsSizeY(0).getValue()
                    success = false;
                    return;
                end
                

                modulo = obj.modulo;


                % TBD add loops for Z & T. For the time being just assume
                % only C > 1
                
                Z = Zarr(1);
                T = Tarr(1);
           
                for c = 1:nchans
                    chan = Carr(c);
                   
                    % check that we are supposed to load this FLIM cube 
                    if ctr == selected  ||  polarisation_resolved  || nfiles >1 
                        
                     
                        % NB moduloAlongC not currently supported!
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
                        end  % end switch
                     
                    end
                    
                    if polarisation_resolved
                        pctr = pctr + 1;
                    else
                        ctr = ctr + 1;
                    end
                        
                   
                end


                %Bodge to suppress bright line artefact on RHS in BH .sdt files
                if strfind(file,'.sdt')
                    obj.data_series_mem(:,:,:,end,:) = 0;
                end



            % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {'.asc','.csv','.txt', '.irf'}

                block = 1;       % deprecated retained for compatibility with old load_flim_files
                
                for c = 1:nchans
                    chan = Carr(c);
                   
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



 
    