 function err = fit(obj, data_series, fit_params, roi_mask, selected)

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


    obj.load_global_library();
   
    
    if nargin < 4
        roi_mask = [];
    end
    if nargin < 5
        selected = [];
    end
    
    % Check if a binning mask has been provided
    if nargin >= 5
        obj.bin = true;
    else
        obj.bin = false;
    end
    
    err = 0;
   
    % If called without arguments we're continuing a fit
    if nargin > 1
        
%TODO:        obj.clear_fit();
        
        obj.data_series = data_series;
        obj.fit_params = fit_params;
        obj.fit_round = 1;
        
        obj.fit_in_progress = true;
        
        delete(obj.fit_result);
        obj.fit_result = flim_fit_result();    
        
        obj.fit_result.width = data_series.width;
        obj.fit_result.height = data_series.height;
        obj.fit_result.binned = obj.bin;
                
    end

    % Get new fitting object
    %obj.get_new_id();

    
    p = obj.fit_params;
    d = obj.data_series;
    
    obj.use_image_irf = d.has_image_irf && ~obj.bin && p.image_irf_mode == 1;
    
    
    % Determine which datasets we need to load and make sure they're loaded
    if p.global_fitting < 2 || p.global_variable == 0
        if false && d.lazy_loading && p.split_fit
            obj.n_rounds = ceil(d.n_datasets/p.n_thread);

            idx = 1:d.n_datasets;
            
            idx = idx/p.n_thread;
            idx = ceil(idx);
            datasets = (idx==obj.fit_round) & d.use';
        else
            datasets = d.use';
            obj.n_rounds = 1;
        end
    else
        var = fieldnames(d.metadata);
        var = var{p.global_variable};
        
        vals = d.metadata.(var);
        
        var_is_numeric = all(cellfun(@isnumeric,vals));
        
        if var_is_numeric
            vals = cell2mat(vals);
            vals = unique(vals);
            vals = num2cell(vals);
        else
            vals = unique(vals);
        end
        
        obj.n_rounds = length(vals);
        cur_var = vals{obj.fit_round};
        
        if var_is_numeric
            datasets = cellfun(@(x) eq(x,cur_var),d.metadata.(var));
        else
            datasets = cellfun(@(x) strcmp(x,cur_var),d.metadata.(var));
        end
        
        datasets = datasets & d.use';
            
    end
     
    sel = 1:d.n_datasets;
    
    if obj.bin
        datasets = (sel == selected);
        obj.n_rounds = 1;
    end

    sel = sel(datasets);
    
    if d.lazy_loading
        d.load_selected_files(sel);
    end    

    if obj.bin
        obj.datasets = 1;
        use = 1;
    else
        obj.datasets = sel;
        use = datasets(d.loaded);
    end
    
    obj.use = use;
        
    obj.im_size = [d.height d.width];
   
    acq = struct();
    acq.data_type = strcmp(d.mode,'tcspc');
    acq.t_rep = 1e6/d.rep_rate;
    acq.polarisation_resolved = d.polarisation_resolved;
    acq.n_chan = d.n_chan;
    acq.counts_per_photon = d.counts_per_photon;
    acq.n_x = d.width;
    acq.n_y = d.height;
    acq.t = d.t;
    acq.t_int = d.t_int;
    
    
    
    % todo: get this from data
    
    if d.use_memory_mapping
        offset_step = 4 * d.n_t * d.n_chan * d.height * d.width;

        for i=1:length(use)
           offset = (use(i)-1) * offset_step + d.mapfile_offset;
           im(i) = ff_FLIMImage('acquisition_parmeters',acq,'mapped_file',d.mapfile_name,'data_offset',offset,'data_class',d.data_type); 
        end
    else
        for i=1:length(use)
           im(i) = ff_FLIMImage('acquisition_parmeters',acq,'data',d.data_series_mem(:,:,:,:)); 
        end
    end
    
    if ~isempty(d.acceptor)
       for i=1:length(use) 
           ff_FLIMImage(im(i),'SetAcceptor',d.acceptor(:,:,use(i)));
       end
    end
    if ~isempty(d.seg_mask)
       for i=1:length(use)
           ff_FLIMImage(im(i),'SetMask',d.mask(:,:,use(i)));
       end
    end
    
    transform = struct();
    transform.smoothing_factor = d.binning;
    transform.t_start = d.t_min;
    transform.t_stop = d.t_max;
    transform.threshold = d.thresh_min;
    transform.limit = d.gate_max;
    
    irf = struct();
    irf.irf = d.irf;
    irf.timebin_t0 = d.t_irf(1);
    irf.timebin_width = d.t_irf(2) - d.t_irf(1);
    irf.ref_reconvolution = d.irf_type;
    irf.ref_lifetime_guess = d.ref_lifetime;
            
    data = ff_FLIMData('images',im,...
                       'data_transformation_settings',transform,...
                       'irf',irf,...
                       'background_value',d.background_value,...
                       'global_mode',p.global_fitting);
            
    % todo: background image, TVB
    
    
    fit_settings = struct();
    fit_settings.n_thread = p.n_thread;
    fit_settings.calculate_errors = p.calculate_errs;
    fit_settings.weighting = p.weighting_mode;
    % TODO ...
     
    ff_Controller(obj.dll_id,'ClearFit');
    ff_Controller(obj.dll_id,'SetData',data);
    ff_Controller(obj.dll_id,'SetModel',p.model);
    ff_Controller(obj.dll_id,'SetFitSettings',fit_settings);
    
    obj.start_time = tic;
   
    ff_Controller(obj.dll_id,'StartFit');
    
    if err ~= 0
        obj.clear_temp_vars();
        return;
    end
                   
    obj.fit_round = obj.fit_round + 1;

    if obj.fit_round == 2

        if err == 0
            obj.fit_timer = timer('TimerFcn',@obj.update_progress, 'ExecutionMode', 'fixedSpacing', 'Period', 0.1);
            start(obj.fit_timer)
        else
            obj.clear_temp_vars();
            msgbox(['Err = ' num2str(err)]);
        end
        
    end
    

end