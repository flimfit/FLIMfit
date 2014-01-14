
function[dims,t_int] = get_image_dimensions(obj, file)


%Finds the dimensions of an image file or set of files including 
% the units alonf the time dimension (delays)


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

    
    t_int = [];
  

    [path,fname,ext] = fileparts(file);

    if strcmp(ext,'.tiff')
        ext = '.tif';
    end
    
    if strcmp(ext,'.tif')
         if length(fname) > 5 && strcmp(fname(end-3:end),'.ome')
             ext = '.ome';
         end
    end
    
    dims.chan_info = { [ ext ' data']};     %default
        
    
    switch ext

        % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case '.tif'
            
            
            dirStruct = [dir([path filesep '*.tif']) dir([path filesep '*.tiff'])];
            noOfFiles = length(dirStruct);
            
            if noOfFiles == 0
                delays = [];
                return
            end
            
            first = [path filesep dirStruct(1).name];
            
            info = imfinfo(first);
            
            
            delays = zeros([1,noOfFiles]);
            
            for f = 1:noOfFiles
                filename = [path filesep dirStruct(f).name];
                [~,name] = fileparts(filename);
                tokens = regexp(name,'INT\_(\d+)','tokens');
                if ~isempty(tokens)
                    t_int(f) = str2double(tokens{1});
                end
                
                tokens = regexp(name,'(?:^|\s)T\_(\d+)','tokens');
                if ~isempty(tokens)
                    delays(f) = str2double(tokens{1});
                else
                    name = name(end-4:end);      %last 6 chars contains delay
                    delays(f) = str2double(name);
                end
                
                
                [dims.delays, sort_idx] = sort(delays);
                
            end
            
             dims.sizeXY = [ info.Width info.Height ];
             dims.FLIM_type = 'Gated';  
             dims.sizeZCT = [1, 1, 1];
             dims.modulo = []; 
                
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
            
            
            omeMeta = r.getMetadataStore();


            sizeZCT(1) = omeMeta.getPixelsSizeZ(0).getValue();
            sizeZCT(2) = omeMeta.getPixelsSizeC(0).getValue();
            sizeZCT(3) = omeMeta.getPixelsSizeT(0).getValue();
            sizeXY(1) = omeMeta.getPixelsSizeX(0).getValue();
            sizeXY(2) = omeMeta.getPixelsSizeY(0).getValue();
            


            % check for presence of an Xml modulo Annotation  containing 'Lifetime'
            na = omeMeta.getXMLAnnotationCount;
            for a = 1:na
                str = omeMeta.getXMLAnnotationNamespace(a - 1);
                if findstr(str,'openmicroscopy.org/omero/dimension/modulo');
                    s = char(omeMeta.getXMLAnnotationValue(a-1));
                    break;
                end

            end


            % if no modulo annotation check for Imspector produced ome-tiffs.
            if isempty(s)
                if findstr(file,'ome.tif')
                    physZ = omeMeta.getPixelsPhysicalSizeZ(0).getValue();
                    dims = obj.parseModuloAnnotation([], sizeZCT, physZ);
                end
            else
                dims = obj.parseModuloAnnotation(s, sizeZCT, []);
            end

            dims.sizeXY = sizeXY;


            
          % single pixel txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
          case {'.csv','.txt'} 
              
              
              if strcmp(ext,'.txt')
                 dlm = '\t';
             else
                 dlm = ',';
             end
              
            fid = fopen(file);
            
            header_data = cell(0,0);     
            textl = fgetl(fid);
            
            if strcmp(textl,'TRFA_IC_1.0')
                fclose(fid_);
                throw(MException('FLIM:CannotOpenTRFA','Cannot open TRFA formatted files'));
            else
            
                while ~isempty(textl)
                    first = sscanf(textl,['%f' dlm]);
                     if isempty(first)
                         header_data{end+1} =  textl;
                         textl = fgetl(fid);
                     else 
                         textl = [];
                     end                 
                end
                
                fclose(fid);
                
                nchans = length(first) -1
                
                n_header_lines = length(header_data);
                header_info = cell(1,n_header_lines);
             
               
                for i=1:n_header_lines
                    parts = regexp(header_data{i},'\s*\t\s*','split');
                    header_info{i} = parts(2:end);
                end
                
                chan_info = cell(1,nchans);
                for i=1:nchans
                    chan_info{i} = header_info{1}{i};
                end
                
               [dims.delays,im_data] = load_flim_file(file,1);
                
                dims.chan_info = chan_info;
                dims.FLIM_type = 'TCSPC';
                dims.sizeZCT = [1 nchans 1];
                dims.sizeXY = [ 1 1 ];
                dims.modulo = [];
            end
                 
                 
            
                 
                 

            
          %  more txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case {'.asc', '.irf'}
             
              
              [dims.delays,im_data,t_int] = load_flim_file(file);
              
              
              dims.FLIM_type = 'Gated';  
              dims.sizeZCT = [1, 1, 1];
              dims.modulo = []; 
              siz = size(im_data);
              dims.sizeXY = siz(end-1: end);
              
            

    end
    
   
    
    if length(t_int) ~= length(dims.delays)
        t_int = ones(size(dims.delays));
    end

end
    