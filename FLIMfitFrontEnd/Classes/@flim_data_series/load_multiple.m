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
    dims = obj.get_image_dimensions(obj.file_names{1});
    
    % this routine should load only FLIM data
    if length(dims.delays) < 2
        errordlg('Data does not appear to be time-resolved. Unable to load!');
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
    
    
    % handle exception where there is only one file or image 
    % so multiple Z, C or T are allowed
    if length(obj.file_names) == 1
        % for the time being assume only 1 dimension can be > 1 
        % otherwise this will go horribly wrong !
        allowed = [ 1 1 1];   % allowed max no of planes in each dimension ZCT
        if polarisation_resolved
            allowed = [ 1 2 1 ];
        end
        prefix = [ 'Z' 'C' 'T'];

        names = [];

        for dim = 1:3
            D = obj.ZCT{dim};
            if length(D) > allowed(dim)
                if dim == 2 && ~isempty(chan_info{1}) 
                    for d = 1:length(D)
                        names{d} = [ prefix(dim)   num2str(D(d) -1) '-' chan_info{d}];
                    end
                else
                    for d = 1:length(D)
                        names{d} = [ prefix(dim)   num2str(D(d) -1) ];
                    end
                end
            end
        end
        if ~isempty(names) 
            obj.names = names;
            obj.n_datasets = length(obj.names);
        end
    
    end

    obj.t = dims.delays;
    obj.channels = obj.ZCT{2};

    
    if obj.polarisation_resolved
         obj.data_size = [length(dims.delays) 2 dims.sizeXY obj.n_datasets ];
    else
        obj.data_size = [length(dims.delays) 1 dims.sizeXY  obj.n_datasets];
    end
    
    
    obj.metadata = extract_metadata(obj.names);
    
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.n_datasets);
    end
    
    
    obj.init_dataset(data_setting_file);
    
end