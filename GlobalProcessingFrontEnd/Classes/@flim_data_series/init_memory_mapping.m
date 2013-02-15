function init_memory_mapping(obj, data_size, num_datasets, mapfile_name)

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
        
    data_preloaded = false;

    if obj.use_memory_mapping
    
        if nargin >= 4
            data_preloaded = true;
            obj.mapfile_name = mapfile_name;
        elseif ~obj.raw
            obj.mapfile_name = global_tempname;
        end

        if ~data_preloaded

            mapfile = fopen(obj.mapfile_name,'w');
        
            if obj.use_popup
                wait_handle=waitbar(0,'Initalising memory mapping...');
            end

            zs = data_size(1:end-1);
            if length(zs) < 2
                zs = [zs 1];
            end
            zd = zeros(zs,'single');
            n_4 = data_size(end);
            for i=1:num_datasets
                for j=1:n_4
                    if ~data_preloaded
                        fwrite(mapfile,zd,'single');
                    end
                end
                if obj.use_popup
                    waitbar(i/num_datasets,wait_handle)
                end
            end
            clear zd;
            fclose(mapfile);
            if obj.use_popup
                close(wait_handle);
            end    

        end

        if ~is64
            repeat = 1;
        else
            if obj.raw
                repeat = obj.num_datasets;
            else
                repeat = num_datasets;
            end
        end

        if obj.raw
            format = 'uint16';
        else
            format = 'single';
        end

        
        obj.memmap = memmapfile(obj.mapfile_name,'Writable',true,'Repeat',repeat,'Format',{format, data_size', 'data_series' },'Offset',obj.mapfile_offset);

        obj.cur_data = obj.memmap.Data(1).data_series;

    end
    
end