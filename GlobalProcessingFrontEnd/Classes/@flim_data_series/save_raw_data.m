function save_raw_data(obj,mapfile_name)

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
    
    if obj.use_popup
        wait_handle=waitbar(0,'Opening files...');
    end
    
    %dataset_name = ['/' obj.names{i} '/' fields{j}];
    %h5create([mapfile_name '.hdf5'],dataset_name,size(im.(fields{j})));
    %h5write([mapfile_name '.hdf5'],dataset_name,im.(fields{j}));
    
    dinfo = struct();
    dinfo.t = obj.t;
    dinfo.t_int = obj.t_int;
    dinfo.names = obj.names;
    dinfo.metadata = obj.metadata;
    dinfo.channels = obj.channels;
    dinfo.data_size = obj.data_size;
    dinfo.polarisation_resolved = obj.polarisation_resolved;
    dinfo.num_datasets = obj.num_datasets;
    dinfo.mode = obj.mode;
    dinfo.root_path = obj.root_path;
    
    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);
              
    mapfile = fopen(mapfile_name,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
    
    for j=1:obj.n_datasets

        file = obj.file_names{j};
        [~,data] = load_flim_file(file,obj.channels);
        
        if isempty(data) || size(data,1) ~= obj.n_t
            data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
        end
        
        c1=fwrite(mapfile,data,'uint16');
      
        if obj.use_popup
            waitbar(j/obj.n_datasets,wait_handle)
        end
        
    end

    fclose(mapfile);
            
    if obj.use_popup
        close(wait_handle)
    end
    
        
end