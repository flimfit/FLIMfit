
function[dims,t_int ] = get_image_dimensions(obj, file)

% Finds the dimensions of an image file or set of files including 
% the units along the time dimension (delays)


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
    dims.delays = [];
    dims.modulo = [];
    dims.FLIM_type = [];
    dims.sizeZCT = [];
  

    [path,name,ext] = fileparts_inc_OME(file);

    
    dims.chan_info = [];
        
    
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
            
             %NB dimensions reversed to retain compatibility with earlier
             %code
             dims.sizeXY = [  info.Height   info.Width ];
             %dims.sizeXY = [ info.Width info.Height ];
             dims.FLIM_type = 'Gated';  
             dims.sizeZCT = [1 1 1];
             dims.modulo = []; 
                
         % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case {'.sdt','.msr','.ome', '.ics', '.bin'}
             
             s = [];
             
             
            % Get the channel filler
            r = loci.formats.ChannelFiller();
            r = loci.formats.ChannelSeparator(r);

            OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
            r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());
            r.setId(file);
           
            
            
            seriesCount = r.getSeriesCount;
            if seriesCount > 1
                block = [];
                while isempty(block) ||  block > seriesCount ||  block < 1 
                    prompt = {['This file holds ' num2str(seriesCount) ' images. Please select one']};
                    dlgTitle = 'Multiple images in File! ';
                    defaultvalues = {'1'};
                    numLines = 1;
                    inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                    block = str2double(inputdata);
                    
                end
                
                obj.block = block;
                
            else
                obj.block = 1;
            end
            
            r.setSeries(obj.block - 1);
            
            omeMeta = r.getMetadataStore();
           
            
            obj.bfOmeMeta = omeMeta;  % set for use in loading data
            obj.bfReader = r;
            
            
            
            sizeZCT(1) = r.getSizeZ;
            sizeZCT(2) = r.getSizeC;
            sizeZCT(3) = r.getSizeT;
            % NB note the inversion of X & Y here 
            sizeXY(1) = r.getSizeY;
            sizeXY(2) = r.getSizeX;
            
          
            % check for presence of an Xml modulo Annotation  containing 'lifetime'
            modlo = [];
            mod = r.getModuloT();
          
            % NB uses 'ifetime' as sometimes L is lower case
            if strfind(mod.type,'ifetime')
                modlo = mod;
                dims.modulo = 'ModuloAlongT';
            else
                mod = r.getModuloC();
                if strfind(mod.type,'ifetime')
                    modlo = mod;
                    dims.modulo = 'ModuloAlongC';
                else
                    mod = r.getModuloZ();
                    if strfind(mod.type,'ifetime')
                        modlo = mod;
                        dims.modulo = 'ModuloAlongZ';
                    end
                end
            end
                
            if ~isempty(modlo)
                
                 if ~isempty(modlo.labels)
                     dims.delays = str2num(modlo.labels)';
                 end
                
                 if ~isempty(modlo.start)
                     if modlo.end > modlo.start
                        nsteps = round((modlo.end - modlo.start)/modlo.step);
                        delays = 0:nsteps;
                        delays = delays .* modlo.step;
                        dims.delays = delays + modlo.start;
                     end
                 end
                 
                
                if ~isempty(strfind(modlo.unit,'NS')) || ~isempty(strfind(modlo.unit,'ns'))
                    dims.delays = dims.delays.* 1000;
                end
                
         
                dims.FLIM_type = char(modlo.typeDescription);
                
                dims.sizeZCT = sizeZCT;
                
       
            else
            % if no modulo annotation check for Imspector produced ome-tiffs.
                if strfind(file,'ome.tif')
                    physZ = omeMeta.getPixelsPhysicalSizeZ(0).getValue();
                    if 1 == sizeZCT(2) && 1 == sizeZCT(3) && sizeZCT(1) > 1
                        physSizeZ = physZ.*1000;     % assume this is in ns so convert to ps
                        dims.delays = (0:sizeZCT(1)-1)*physSizeZ;
                        dims.modulo = 'ModuloAlongZ';
                        dims.FLIM_type = 'TCSPC';
                        sizeZCT(1) = sizeZCT(1)./length(dims.delays); 
                        dims.sizeZCT = sizeZCT;
                    end
                end
                
                
                % support for .ics files lacking a Modulo annotation
                if strfind(file,'.ics')
                    text = r.getMetadataValue('history extents');
                    text = strrep(text,'?','');
                    decay_range  = str2num(text) * 1e12;  % convert to ps
                    delays = 0:sizeZCT(2) -1;
                    step = decay_range/sizeZCT(2);
                    dims.delays = delays .* step;
                    dims.modulo = 'ModuloAlongC';
                    dims.sizeZCT = [ 1 1 1 ];
                    dims.FLIM_type = 'TCSPC';
                end
                
            end
            
            

             % get channel_names
            for c = 1:sizeZCT(2)
                chan_info{c} = omeMeta.getChannelName( 0 ,  c -1 );
                if isempty(chan_info{c})
                    chan_info{c} = omeMeta.getChannelEmissionWavelength(0, c -1);
                end
                if isempty(chan_info{c})
                    chan_info{c} = char(omeMeta.getChannelID(0, c -1));
                end

                dims.chan_info = chan_info;
            end
          

            
            dims.sizeXY = sizeXY;
           


            
          % single pixel txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
          case {'.csv','.txt'} 
              
              if strcmp(ext,'.txt')
                  dlm = '\t';
              else
                  dlm = ',';
              end
              
              
              header_data = obj.parse_csv_txt_header(file);
             
              n_header_lines = length(header_data);
              
              header_info = cell(1,n_header_lines);
              
              n_chan = 0;
              for i=1:n_header_lines
                  parts = regexp(header_data{i},[ '\s*' dlm '\s*' ],'split');
                  header_info{i} = parts(2:end);
                  n_chan = max(length(header_info{i}),n_chan);
              end
              
              chan_info = cell(1,n_chan);
              
              for i=1:n_chan
                  chan_info{i} = header_info{1}{i};
              end
              
              
              ir = dlmread(file,dlm,n_header_lines,0);
              obj.txtInfoRead = ir;    % save ir into class
              
              delays(1,:) = ir(:,1);
              
              delays = delays(~isnan(delays));
              
              if max(delays) < 1000
                  delays = delays * 1000;
              end
              
              dims.delays = delays;
             
              dims.chan_info = chan_info;
              dims.FLIM_type = 'TCSPC';
              dims.sizeZCT = [1 n_chan 1];
              dims.sizeXY = [ 1 1 ];
              dims.modulo = [];
              
    
          %  more txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          case {'.asc'}  
              
              [obj.txtInfoRead,delays] = obj.parse_asc_txt(file);
         
              siz = size(obj.txtInfoRead);
              if length(siz) == 2 % single pixel data 1xn or nx1
                dims.sizeXY = [1 1];
              else
                dims.sizeXY = siz(end -1 : end);
              end
              dims.delays = delays;
              dims.FLIM_type = 'TCSPC';  
              dims.sizeZCT = [1, 1, 1];
              dims.modulo = []; 
              
              
              
          case {'.irf'}
              
              ir = load(file);
              obj.txtInfoRead = ir;    % save ir into class
              
              dims.delays(1,:) = ir(:,1);
              dims.FLIM_type = 'TCSPC';  
              dims.sizeZCT = [1, 1, 1];
              dims.modulo = []; 
              dims.sizeXY = [ 1 1 ];
              
              
              
        otherwise 
              errordlg('Error: Unknown File Extension!');
              return; 
            

    end
    
   
    
    if length(t_int) ~= length(dims.delays)
        t_int = ones(size(dims.delays));
    end

end
    