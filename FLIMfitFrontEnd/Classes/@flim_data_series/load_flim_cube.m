
function[data_cube] = load_flim_cube(obj, file, selected)


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

    sizet = length(obj.t);
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
    
    npol = 1;       % default no of polarised channels
    
    if obj.polarisation_resolved
        npol = 2;
    end
    
 
    data_cube = single(zeros(sizet, npol, sizeX, sizeY )); 
   
    
    ctr = 1;       %  Count of FLIM_cubes loaded so far
    pctr= 1;       % polarised counter (should only go up to 2)
 

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

                delays = obj.t;

                if length(dirStruct) ~= sizet
                    data_cube = [];
                    return
                end

                for t = 1:sizet

                    % find the filename which matches the first delay
                    str = num2str(delays(t));
                    ff = 1;
                    while isempty(strfind(dirStruct(ff).name, str))
                        ff = ff + 1;
                        if ff > sizet 
                            return;
                        end
                    end

                    filename = [path filesep dirStruct(ff).name];
                    [~,name] = fileparts(filename);

                    try
                        plane = imread(filename,'tif');
                        data_cube(t,1,:,:,file_count) = plane';
                    catch error
                        throw(error);
                    end

                end

                if min(data_cube(:)) > 32500
                    data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
                end


             % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
             case {'.sdt','.msr','.ome'}

                 s = [];

                 autoloadBioFormats = 1;

                % Toggle the stitchFiles flag to control grouping of similarly
                % named files into a single dataset based on file numbering.
                stitchFiles = 0;

                % load the Bio-Formats library into the MATLAB environment
                status = bfCheckJavaPath(autoloadBioFormats);
                assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
                    'to the static Java path or add it to the Matlab path.']);

                % initialize logging
                loci.common.DebugTools.enableLogging('INFO');

                % Get the channel filler
                r = bfGetReader(file, stitchFiles);

                modulo = obj.modulo;

                if ~strcmp(modulo,'ModuloAlongC') && ~strcmp(modulo,'ModuloAlongT') && ~strcmp(modulo,'ModuloAlongZ')
                    [ST,I] = dbstack('-completenames');
                    errordlg(['No acceptable ModuloAlong* in the function ' ST.name]);
                    return;
                end;    

                % TBD add loops for Z & T. For the time being just assume
                % only C > 1
                
                Z = Zarr(1);
                T = Tarr(1);
           
                for c = 1:nchans
                    chan = Carr(c);
                    
                    if ctr == selected        % check that we are supposed to load this FLIM cube
                    
                        % NB moduloAlongC not currently supported!
                        switch modulo
                            case 'ModuloAlongT'
                                T = T * sizet;
                                for t = 0:sizet -1
                                    index = r.getIndex(Z, chan ,T + t);
                                    plane = bfGetPlane(r,index + 1);
                                    data_cube(t +1,pctr,:,:) = plane;
                                end

                            case 'ModuloAlongZ'
                                Z = Z * sizet;
                                for t = 0:sizet -1
                                    index = r.getIndex(Z + t, chan ,T);
                                    plane = bfGetPlane(r,index + 1);
                                    data_cube(t+1,pctr,:,:) = plane;
                                end
                        end  % end switch
                        
                        if obj.polarisation_resolved
                            pctr = pctr + 1;
                        else
                            ctr = ctr + 1;
                        end
                        
                    end

                end



                %Bodge to suppress bright line artefact on RHS in BH .sdt files
                if strfind(file,'.sdt')
                    data_cube(:,:,:,end,:) = 0;
                end



            % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {'.asc','.csv','.txt', '.irf'}

                   block = 1;       % deprecated retained for compatibility with old load_flim_files
                  [delays,data_cube(:,1,:,:,1),t_int] = load_flim_file(file,obj.channels,block);




        end         % end switch



 
    