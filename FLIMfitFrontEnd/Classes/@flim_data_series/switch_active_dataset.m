function switch_active_dataset(obj, dataset, no_smoothing)
    %> Switch which dataset in the memory mapped file we're pointing at
    
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
        no_smoothing = ~obj.use_smoothing;
    end
    
    if (dataset == obj.active && (no_smoothing || obj.cur_smoothed)) ...
            || dataset <= 0 || dataset > obj.n_datasets
        return
    end
    
    if obj.use_memory_mapping
        
        if obj.loaded(dataset)

            tr_idx = sum(obj.loaded(1:dataset));

            if obj.raw
                idx = dataset;
            else
                idx = tr_idx;
            end

            if ~isempty(obj.memmap)
                obj.cur_data = obj.memmap.Data(idx).data_series;
            end

        else

            obj.read_selected_files(dataset);

        end
        
    else
       
        obj.cur_data = obj.data_series_mem(:,:,:,:,dataset);
               
    end
 
    obj.active = dataset;
    
    obj.compute_tr_data(false,no_smoothing);
        
end