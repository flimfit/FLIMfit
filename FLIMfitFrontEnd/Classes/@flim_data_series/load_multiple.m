function load_multiple(obj, polarisation_resolved, data_setting_file)   
    %> Load a series of FLIM data files
    
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

    % Author : Sean Warren
    
    % get dimensions from first file
    [dims,~,obj.reader_settings] = obj.get_image_dimensions(obj.file_names{1});
    
    if isempty(dims.delays)     % cancelled out
        if ~isempty(dims.error_message)
            errordlg(dims.error_message);
        end
        return;
    end
    
    % this routine should load only FLIM data
    if length(dims.delays) < 2
        if isempty(dims.error_message)
            errordlg('Data does not appear to be time-resolved. Unable to load!');
        else
            errordlg(dims.error_message);
        end
        return;
    end;
    
    chan_info = dims.chan_info;
    obj.modulo = dims.modulo;
    obj.mode = dims.FLIM_type;

    % Determine which planes we need to load 
    obj.ZCT = obj.get_ZCT( dims, polarisation_resolved, dims.chan_info );
    
    if isempty(obj.ZCT)
        return;
    end
    
    if polarisation_resolved
        n_chan = 2;
    else
        n_chan = 1;
    end
    
    % handle exception where  multiple Z, C or T are allowed
    % for the time being assume only 1 dimension can be > 1 
    % (as enforced in ZCT_selection) otherwise this will go horribly wrong !
    allowed = [ 1 n_chan 1 ];
    prefix = [ 'Z' 'C' 'T'];
    
    dim = find(cellfun(@length,obj.ZCT) > allowed,1);    
    if ~isempty(dim)
        p = prefix(dim);
        D = obj.ZCT{dim};

        names = cell(1,length(D)*length(obj.file_names));
        filename = names;
        metadata = struct();
        
        na = 1;
        for f = 1:length(obj.file_names)
            name = obj.names{f};
            for d = 1:length(D)
                if p == 'C' && ~isempty(chan_info)
                    names{na} = [ p num2str(D(d) -1) '-' chan_info{D(d)} ];
                    metadata.(p){na} = chan_info{D(d)};
                else
                    names{na} = [ p num2str(D(d)-1) '-' name ];
                    metadata.(p){na} = D(d)-1;
                end
                filename{na} = name;
                na = na + 1;
            end
        end
        obj.load_multiple_planes = dim;
        obj.metadata = extract_metadata(filename,metadata);
        obj.names = names;
        obj.n_datasets = length(obj.names);
    end
        
    obj.t = dims.delays;
    obj.channels = obj.ZCT{2};

    obj.data_size = [length(dims.delays) n_chan dims.sizeXY obj.n_datasets];
     
    if isempty(obj.metadata)
        obj.metadata = extract_metadata(obj.names);
    end
       
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.n_datasets);
    end
   
    obj.init_dataset(data_setting_file);
      
end