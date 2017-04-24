function load_raw_data(obj,file)

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

    mapfile = fopen(file,'r');
    
    % retained for compatibility with old .raw files
    ser_len = fread(mapfile,1,'uint16');
    offset = 2;
    
    % new style raw file so length is now 64 bits
    if ser_len == 0
        offset = offset + 8;
        ser_len = fread(mapfile,1,'uint64');
    end
    
    
    ser_info = fread(mapfile,ser_len,'uint8');

    fname = [global_tempname '.mat'];
    fid = fopen(fname,'w');
    fwrite(fid,ser_info,'uint8');
    load(fname);
    fclose(fid);
    delete(fname);
    
    fclose(mapfile);
        
    obj.suspend_transformation = true;
    
    fields = fieldnames(dinfo);
    for i=1:length(fields)
        
        if strcmp(fields{i},'num_datasets')
            new_field = 'n_datasets'; % account for legacy files
        else
            new_field = fields{i};
        end
        
        eval(['obj.' new_field '= dinfo.' fields{i} ';']);

    end
    
    obj.suspend_transformation = false;
            
    obj.raw = true;
    obj.mapfile_offset = ser_len + offset;
    obj.mapfile_name = file;
        
    if size(obj.irf,2) > size(obj.irf,1)
        obj.irf = obj.irf';
    end
    
    obj.load_selected_files(1:obj.n_datasets);
    
    if isempty(obj.root_path)
        obj.root_path = ensure_trailing_slash(fileparts(file));
    end
    
    obj.init_dataset([]);
end