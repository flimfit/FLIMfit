function set_data(obj,t,data,polarisation_resolved)
    %> Set data from memory
    
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

    obj.root_path = '';
    obj.mode = '';
    
    if nargin < 4
        obj.polarisation_resolved = false;
    else
        obj.polarisation_resolved = polarisation_resolved;
    end
    
    data = obj.ensure_correct_dimensionality(data);
    
    obj.t = t;
    
    if ndims(data) > 4
        obj.num_datasets = size(data,5);
    else
        obj.num_datasets = 1;
    end
    
    % Set names
    %--------------------------------------
    
    nstr = 1:obj.num_datasets;
    nstr = num2cell(nstr);
    nstr = cellfun(@(x)num2str(x),nstr,'UniformOutput',false);
    obj.names = nstr;   
    
    obj.use_memory_mapping = false;
    obj.loaded = ones([1 obj.n_datasets]);
    
    obj.data_series_mem = data;
    
    
    
    % Write to mem map file
    %--------------------------------------
    %{
    mapfile_name = global_tempname;
    tr_mapfile_name = global_tempname;
        
    mapfile = fopen(mapfile_name,'w');
    tr_mapfile = fopen(tr_mapfile_name,'w');
    
    fwrite(mapfile,data,'double');
    fwrite(tr_mapfile,data,'double');
 
    fclose(mapfile);
    fclose(tr_mapfile);
    %}
    % Initialise
    %--------------------------------------
 
    %obj.init_memory_mapping(obj.data_size, obj.num_datasets, mapfile_name, tr_mapfile_name);   
    
    obj.switch_active_dataset(1);
    
    obj.init_dataset();
    
end