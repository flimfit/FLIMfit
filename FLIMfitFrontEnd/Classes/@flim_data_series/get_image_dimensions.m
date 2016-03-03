
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
    dims.error_message = [];
 
  
    [ext,r] = obj.init_bfreader(file);
    
    dims.chan_info = [];
        
    
    switch ext
      
         % bioformats files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
         case '.bio'
             
            s = [];
            
            omeMeta = r.getMetadataStore();
           
            seriesCount = r.getSeriesCount;
            
            if seriesCount > 1
                if omeMeta.getPlateCount > 0
                    % plate! so check imageSeries has been setup or throw error
                    if obj.imageSeries == -1 | length(obj.imageSeries) ~= length(obj.file_names)
                        dims.error_message = ' This file contains Plate data. Please load using the appropriate menu item';
                        return;
                    end
                else
                    str = num2str((0:seriesCount - 1)');
                    prompt = [{sprintf(['This file holds ' num2str(seriesCount) ' images. Numbered 0-' num2str(seriesCount -1) '\nPlease select one'])} {''}];
                    imageSeries = listdlg('PromptString',prompt,'SelectionMode','single','ListString',str);
                    if isempty(imageSeries)
                        return;
                    end
                    
                    % set series for each file to that selected 
                    obj.imageSeries = ones(1,length(obj.file_names)) .* imageSeries; 
                end
            else
                obj.imageSeries = ones(1,length(obj.file_names));
            end
            
            
            r.setSeries(obj.imageSeries(1) - 1);
            
            
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
                    if  1 == sizeZCT(2) && 1 == sizeZCT(3) && sizeZCT(1) > 1
                        physZ = omeMeta.getPixelsPhysicalSizeZ(0);
                        if ~isempty(physZ) 
                            physSizeZ = physZ.value.doubleValue() .*1000;     % assume this is in ns so convert to ps
                            dims.delays = (0:sizeZCT(1)-1)*physSizeZ;
                            dims.modulo = 'ModuloAlongZ';
                            dims.FLIM_type = 'TCSPC';
                            sizeZCT(1) = sizeZCT(1)./length(dims.delays); 
                            dims.sizeZCT = sizeZCT;
                        end
                    end
                end
                
                
                % support for .ics files lacking a Modulo annotation
                if strfind(file,'.ics')
                    text = r.getMetadataValue('history extents');
                    text = strrep(text,'?','');
                    decay_range  = str2Double(text) * 1e12;  % convert to ps
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
                chan_info{c} = char(omeMeta.getChannelName( 0 ,  c -1 ));
                if isempty(chan_info{c})
                    chan_info{c} = char(omeMeta.getChannelEmissionWavelength(0, c -1));
                end
                if isempty(chan_info{c})
                    chan_info{c} = ['Channel:' num2str(c-1)];
                end

                dims.chan_info = chan_info;
            end
          

            if isempty(dims.delays)
                dims.error_message = 'Unable to load! Not time resolved data.';
            end
            dims.sizeXY = sizeXY;
           

        case {'.pt3','.ptu','.bin','.bin2'}
            
            r = FLIMreaderMex(file);
            FLIMreaderMex(r,'SetSpatialBinning',2);
            n_channels = FLIMreaderMex(r,'GetNumberOfChannels');
            dims.delays = FLIMreaderMex(r,'GetTimePoints');
            dims.sizeZCT = [ 1 n_channels 1 ];
            dims.FLIM_type = 'TCSPC';
            dims.sizeXY = FLIMreaderMex(r,'GetImageSize');
            FLIMreaderMex(r,'Delete');
            
            for i=1:n_channels
                dims.chan_info{i} = ['Channel:' num2str(i-1)];
            end
    
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
            
            for f = 1:noOfFiles
                filename = [path filesep dirStruct(f).name];
                [~,name] = fileparts(filename);
                tokens = regexp(name,'INT\_(\d+)','tokens');
                if ~isempty(tokens)
                    t_int(f) = str2double(tokens{1});
                end
                
                tokens = regexp(name,'(?:^|\s)T\_(\d+)','tokens');
                if ~isempty(tokens)
                    del = str2double(tokens{1});
                else
                    sname = name(end-4:end);      %last 6 chars contains delay
                    del = str2double(sname);  
                end
                if isnan(del)
                    errordlg(['Unable to parse filename: ' name]);
                    dims.delays = [];
                    return;
                else
                    delays(f) = del;
                end
                
                [dims.delays, sort_idx] = sort(delays);
                
            end
            
            if length(delays) < 3
                dimd.delays = [];
                errordlg('Too few valid .tif files found!!');
                return;
            end
            
             %NB dimensions reversed to retain compatibility with earlier
             %code
             dims.sizeXY = [  info.Height   info.Width ];
             %dims.sizeXY = [ info.Width info.Height ];
             dims.FLIM_type = 'Gated';  
             dims.sizeZCT = [1 1 1];
             dims.modulo = []; 
            
            
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
              
              n_chan = zeros(1,n_header_lines);
              wave_no = [];
              
              for i=1:n_header_lines
                  parts = regexp(header_data{i},[ '\s*' dlm '\s*' ],'split');
                  header_info{i} = parts(2:end);
                  tag = parts{1};
                  % find which line describes wavelength
                  if strfind(lower(tag),'wave')
                      wave_no = i;
                  end
                  n_chan(i) = length(header_info{i});
              end
              n_chan = min(n_chan);
              
              chan_info = cell(1,n_chan);
              
              % by default use well for chan_info
              for i=1:n_chan
                  chan_info{i} = header_info{1}{i};
              end
              
              % catch headerless or unreadable headers
              if isempty(n_chan) | n_chan < 1
                  n_chan = 1;
                  chan_info{1} = '1';
              end
              
              if n_chan > 1  && ~isempty(wave_no)  % no point in following code for a single channel
                  % if all wells appear to be the same 
                  % then use wavelength instead
                  if strcmp(chan_info{1} ,chan_info{end})
                    % check size matches
                    if length(header_info{wave_no}) > 2  &&  length(header_info{wave_no}) == n_chan
                        for i=1:n_chan
                          chan_info{i} = header_info{wave_no}{i};
                        end
                    end
                  end
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
    