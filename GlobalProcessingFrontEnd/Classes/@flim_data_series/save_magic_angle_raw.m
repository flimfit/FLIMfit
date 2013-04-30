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
    
    frame_binning = 1;
    
    if ~obj.polarisation_resolved
        warning('Data must be polarisation resolved to export magic angle!')
        return
    end
    
    if obj.use_popup
        wait_handle=waitbar(0,'Saving raw file...');
    end
    
    %dataset_name = ['/' obj.names{i} '/' fields{j}];
    %h5create([mapfile_name '.hdf5'],dataset_name,size(im.(fields{j})));
    %h5write([mapfile_name '.hdf5'],dataset_name,im.(fields{j}));
        
    field_names = fieldnames(obj.metadata);
    for i=1:length(field_names)
       
        md = obj.metadata.(field_names{i});
        new_metadata.(field_names{i}) = md(1:frame_binning:end);
        
    end
    
    num_binned_frames = ceil(obj.num_datasets / frame_binning);
    
    dinfo = struct();
    dinfo.t = obj.tr_t;
    dinfo.t_int = obj.tr_t_int;
    dinfo.names = obj.names(1:frame_binning:end);
    dinfo.metadata = new_metadata;
    dinfo.data_size = obj.data_size;
    dinfo.num_datasets = num_binned_frames;
    dinfo.mode = obj.mode;
    dinfo.root_path = obj.root_path;
    dinfo.data_type = 'single';
    
    dinfo.data_size(1) = length(obj.tr_t);
    dinfo.data_size(2) = 1;
    dinfo.channels = 1;
    dinfo.polarisation_resolved = false;
    
    
    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);
              
    mapfile = fopen(mapfile_name,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
        
    idx = 1;
    for j=1:num_binned_frames

        data = 0;
        
        for i=1:frame_binning
            if idx <= obj.num_datasets
                obj.switch_active_dataset(idx);
                f_data = obj.cur_tr_data;
                f_data = f_data(:,1,:,:) + 2*obj.g_factor*f_data(:,2,:,:);
                data = data + f_data;
                if isempty(data) || size(data,1) ~= length(obj.tr_t)
                    data = zeros([obj.n_t 1 obj.height obj.width]);
                end
                idx = idx + 1;
                
                if obj.use_popup
                    waitbar(idx/obj.num_datasets,wait_handle)
                end
            end
        end
        c1=fwrite(mapfile,data,'single');

        
    end

    
    fclose(mapfile);
            
    if obj.use_popup
        close(wait_handle)
    end
    
        
end