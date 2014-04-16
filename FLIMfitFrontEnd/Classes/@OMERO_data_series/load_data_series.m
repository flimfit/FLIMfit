function load_data_series(obj,images, polarisation_resolved, data_setting_file)   
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
    
    
   
    if nargin < 3
        data_setting_file = [];
    end
    
    block = [];
    
    n_datasets = length(images);
    
    obj.file_names = images;
    
   
    % get dimensions from first file
    dims = obj.get_image_dimensions(images{1});

    obj.modulo = dims.modulo;

    obj.mode = dims.FLIM_type;

    % Determine which channels we need to load 
    obj.ZCT = obj.get_ZCT( dims, polarisation_resolved );

    obj.t = dims.delays;
    obj.channels = obj.ZCT{2};

    obj.n_datasets = n_datasets;

    if obj.polarisation_resolved
         obj.data_size = [length(dims.delays) 2 dims.sizeXY 1 ];
    else
        obj.data_size = [length(dims.delays) 1 dims.sizeXY 1 ];
    end

 
    obj.metadata = extract_metadata(obj.names);
       
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.n_datasets);
    end
    
    
    obj.init_dataset(data_setting_file);
    
end