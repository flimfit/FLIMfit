function init_dataset(obj,setting_file_name)
    %> Initalise dataset after we've loaded in the data
    
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
    
  
    prof = get_profile();    
   
    
    % Set defaults for background depending on type of data
    if strcmp(obj.mode,'TCSPC')
        obj.background_value = 0;
        obj.background_type = 0;
    else
        background_val = prof.Data.Default_Camera_Background;
        
        % Check that setting background isn't going to completely mask out
        % data
        if min(obj.cur_tr_data(:)) <= background_val
            obj.background_value = 0;
            obj.background_type = 0;
        else
            obj.background_value = background_val;
            obj.background_type = 1;
        end
    end
    
    if ~isfinite(obj.rep_rate)
        obj.rep_rate = prof.Data.Default_Rep_Rate;
    end
    
    obj.background_image = [];
    
    obj.mask = ones([obj.height obj.width obj.n_datasets],'uint16');
    obj.seg_mask = [];
    
    obj.intensity = [];
    obj.mask = [];
    obj.thresh_mask = [];
    obj.seg_mask = [];
    obj.multid_mask = [];
    obj.intensity_normalisation = [];
    
    obj.use = true(obj.n_datasets,1);
    
    obj.binning = 1;
    obj.thresh_min = 1;
    obj.gate_max = prof.Data.Default_Gate_Max;
    
    obj.t_min = min(obj.t);
    obj.t_max = max(obj.t);  
   
    obj.irf.polarisation_resolved = obj.polarisation_resolved;
    obj.irf.data_t_min = obj.t_min;
    obj.irf.n_chan = obj.n_chan;
    obj.irf.init();
                 
    obj.data_size = size(obj.cur_data);
    obj.data_size = [obj.data_size ones(1,4-length(obj.data_size))];
    
    % If a data setting file exists load it
    
    if obj.polarisation_resolved
        obj.polarisation(1) = Polarisation.Parallel;
        obj.polarisation(2) = Polarisation.Perpendicular;
    end
    
    if nargin < 2 || isempty(setting_file_name)
        if obj.polarisation_resolved
            setting_file_name = [obj.root_path 'polarisation_data_settings.xml'];
        else
            setting_file_name = [obj.root_path 'data_settings.xml'];
        end
    end
    
    if nargin >= 2
       obj.load_data_settings(setting_file_name); 
    end
    
    % if single-pixel, single line or single column image then force no smoothing
    if obj.data_size(3) == 1 || obj.data_size(4) == 1
        obj.binning = 0;
        notify(obj,'masking_updated');
    end
    
    obj.init = true;
    
    if isempty(obj.t_int)
        obj.t_int = ones(size(obj.t));
    end
    if isempty(obj.counts_per_photon)
        obj.counts_per_photon = 1;
    end
    
    if numel(obj.polarisation) ~= obj.n_chan
        obj.polarisation = zeros([1, obj.n_chan]);
    end

    
    obj.compute_tr_data();

end