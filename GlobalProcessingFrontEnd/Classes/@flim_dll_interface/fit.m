function err = fit(obj, data_series, fit_params, roi_mask, selected, grid)

    obj.load_global_library();
    
    if nargin < 4
        roi_mask = [];
    end
    if nargin < 5
        selected = [];
    end

    if nargin >= 5 % binning mask provided
        obj.bin = true;
        if nargin < 6
            obj.grid = false;
        end
        obj.grid = grid;
    else
        obj.bin = false;
        obj.grid = false;
    end
    
    err = 0;
   

    if nargin > 1
        obj.data_series = data_series;
        obj.fit_params = fit_params;
        obj.fit_round = 1;
        
        obj.fit_in_progress = true;
        
        obj.fit_result = flim_fit_result();    

        if obj.bin
            obj.fit_result.init(1);
        else
            n_im = sum(obj.data_series.n_datasets);
            obj.fit_result.init(n_im,obj.fit_params.use_memory_mapping);
        end
        obj.fit_result.binned = obj.bin;
        obj.fit_result.names = obj.data_series.names;
                
    end

    p = obj.fit_params;
    d = obj.data_series;
    
    if p.global_fitting < 2
        if d.lazy_loading && p.split_fit
            obj.n_rounds = ceil(d.num_datasets/p.n_thread);

            idx = 1:d.num_datasets;
            
            idx = idx/p.n_thread;
            idx = ceil(idx);
            datasets = (idx==obj.fit_round);
        else
            datasets = true(1,d.num_datasets);
            obj.n_rounds = 1;
        end
    elseif p.global_variable == 0
        datasets = true(1,d.num_datasets);
        obj.n_rounds = 1;
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
            
    end
    
    sel = 1:d.num_datasets;
    
    if obj.bin
        datasets = (sel == selected);
        obj.n_rounds = 1;
    end

    
    sel = sel(datasets);
    
    %{
    flds = fields(obj.data_series.metadata);
    obj.fit_result.metadata = struct();
    for i=1:length(flds);
        obj.fit_result.metadata.(flds{i}) = obj.data_series.metadata.(flds{i})(datasets);
    end
    %}
    obj.fit_result.metadata = obj.data_series.metadata;
    

    if d.lazy_loading
        d.load_selected_files(sel);
    end    
        
    loaded_datasets = d.loaded & datasets;
    n_datasets = sum(datasets);
    
    obj.datasets = sel;
    obj.loaded_datasets = loaded_datasets;

    width = d.width;
    height = d.height;
    n_im = n_datasets;
    
    if obj.bin == true
        
        obj.n_group = 1;
        obj.n_regions = 1;
        obj.n_regions_total = 1;
        
        obj.n_px = 1;
        
        mask = 1;
        
        obj.globals_size = [1 1];
        
        if p.use_phase_plane_estimation   
            est_decay = obj.data_series.get_roi(roi_mask,selected);
            est_decay = squeeze(nansum(est_decay,2));
        end
        
    else
        %{
        c = 1:sum(d.loaded);
        sel = datasets(logical(d.loaded));
        c = c(sel);
        mask = d.mask(:,:,c);
        %}
        %{
        mask = d.mask;
        flt = obj.data_series.use(obj.data_series.loaded);
        mask = mask(:,:,flt);
        %}
        
        mask = d.seg_mask; 
        
        switch p.global_fitting
            case 0
                obj.n_group = width * height * n_im;            
                
                if ~isempty(mask)
                    obj.n_regions = mask;
                    obj.n_regions_total = max(mask(:));
                else
                    obj.n_regions = ones([width height n_im]);
                    obj.n_regions_total = obj.n_group;
                end
                
                obj.n_px = 1;
                obj.globals_size = [width height n_im];
                
                if p.use_phase_plane_estimation         
                    est_decay = d.data_series;
                end



            case 1 %global_mode.image
                obj.n_group = n_im;
                
                if ~isempty(mask)
                    obj.n_regions = reshape(mask,[size(mask,1)*size(mask,2) size(mask,3)]);
                    obj.n_regions = squeeze(max(obj.n_regions,[],1));
                else
                    obj.n_regions = ones([1 n_im]);
                end
                obj.n_regions_total = sum(obj.n_regions);

                obj.n_px = width * height;
                obj.globals_size = [1 obj.n_regions_total];
                
                if p.use_phase_plane_estimation         
                    est_decay = zeros(d.n_tr_t,n_im);
                    
                    for i=1:n_im
                        masked = d.get_roi([],i);
                        sz = size(masked);
                        decay = nansum(reshape(masked,[sz(1) prod(sz(2:end))]),2);
                        est_decay(:,i) = decay;
                    end
                end


            case 2 %global_mode.dataset
                obj.n_group = 1;
                
                if ~isempty(mask)
                    obj.n_regions = max(mask(:));
                else
                    obj.n_regions = 1;
                end
                obj.n_regions_total = obj.n_regions;

                obj.n_px = width * height * n_im;
                obj.globals_size = [1 obj.n_regions_total];
                
                if p.use_phase_plane_estimation          
                    est_decay = zeros(d.n_t,1);
                    
                    for i=1:n_im
                        masked = d.get_roi([],i);
                        sz = size(masked);
                        decay = nansum(reshape(masked,[1 prod(sz(2:end))]),2);
                        est_decay = est_decay + decay;
                    end
                end
        end
        
    end
    
    % Phase plane estimation
    if p.use_phase_plane_estimation
        p.tau_guess = obj.generate_phase_plane_estimates(d,est_decay,p.n_exp,p.tau_min,p.tau_max);
    end
    
    obj.single_guess = ~p.use_phase_plane_estimation;
    
    
    obj.n_regions = double(obj.n_regions);

    if obj.bin
        sz = [1 1];
    else
        sz = [height width n_im];
    end
    
    obj.I0_size = sz;
    obj.tau_size = [p.n_exp sz];
    
    obj.theta_size = [p.n_theta sz];
    obj.r_size = [p.n_theta sz];
    
    n_decay_group = p.n_fret + p.inc_donor;
    obj.gamma_size = [n_decay_group sz];
    obj.E_size = [p.n_fret sz];
    

    obj.p_tau_guess = libpointer('doublePtr',p.tau_guess);
    obj.p_tau_min = libpointer('doublePtr',p.tau_min);
    obj.p_tau_max = libpointer('doublePtr',p.tau_max);
    obj.p_irf  = libpointer('doublePtr', d.tr_irf);
    obj.p_t_irf = libpointer('doublePtr', d.tr_t_irf);
    obj.p_n_regions = libpointer('int32Ptr', int32(obj.n_regions));
    obj.p_fixed_beta = libpointer('doublePtr',p.fixed_beta / sum(p.fixed_beta));
    obj.p_E_guess = libpointer('doublePtr',p.fret_guess);
    obj.p_theta_guess = libpointer('doublePtr',p.theta_guess);

    obj.p_tvb_profile = libpointer('doublePtr',d.tr_tvb_profile);

    if p.polarisation_resolved
        obj.p_r = libpointer('doublePtr',zeros(obj.r_size));
        obj.p_theta = libpointer('doublePtr',zeros(obj.theta_size));

        obj.p_E = [];
        obj.p_gamma = [];
    else
        obj.p_E = libpointer('doublePtr',zeros(obj.E_size));
        obj.p_gamma = libpointer('doublePtr',zeros(obj.gamma_size));

        obj.p_r = [];
        obj.p_theta = [];
    end

    if ~d.use_memory_mapping
        obj.p_data = libpointer('doublePtr', d.data_series_mem);
    end

    obj.p_tau = libpointer('doublePtr', zeros(obj.tau_size));
    obj.p_beta = libpointer('doublePtr', zeros(obj.tau_size));

    obj.p_I0 = libpointer('doublePtr', zeros(obj.I0_size));

    if false
        obj.p_t0 = libpointer('doublePtr', zeros(obj.I0_size));
    end
    %else
    %    obj.p_t0 = 0;
    %end

    if p.fit_offset > 0
        obj.p_offset = libpointer('doublePtr',zeros(obj.I0_size));
    else
          obj.p_offset = [];
    end

    if p.fit_scatter > 0
        obj.p_scatter = libpointer('doublePtr',zeros(obj.I0_size));
    else
          obj.p_scatter = [];
    end

    if p.fit_tvb > 0
        obj.p_tvb = libpointer('doublePtr',zeros(obj.I0_size));
    else
          obj.p_tvb = [];
    end

    if p.ref_reconvolution == 2
        obj.p_ref_lifetime = libpointer('doublePtr',zeros(obj.I0_size));
    else
          obj.p_ref_lifetime = [];
    end

    obj.p_tau_err = [];
    obj.p_beta_err = [];
    obj.p_theta_err = [];
    obj.p_E_err = [];
    obj.p_offset_err = [];
    obj.p_scatter_err = [];
    obj.p_tvb_err = [];
    obj.p_ref_lifetime_err = [];

    if p.calculate_errs && ~obj.bin
        obj.p_tau_err = libpointer('doublePtr', zeros(obj.tau_size));

        if p.fit_beta == 2
            obj.p_beta_err = libpointer('doublePtr',zeros(obj.tau_size));
        end

        if p.polarisation_resolved
            obj.p_theta_err = libpointer('doublePtr',zeros(obj.theta_size));
        else
            obj.p_E_err = libpointer('doublePtr',zeros(obj.E_size));
        end

        if p.fit_offset == 2
            obj.p_offset_err = libpointer('doublePtr',zeros(obj.I0_size));
        end
        if p.fit_scatter == 2
            obj.p_scatter_err = libpointer('doublePtr',zeros(obj.I0_size));
        end
        if p.fit_tvb == 2
            obj.p_tvb_err = libpointer('doublePtr',zeros(obj.I0_size));
        end
        if p.ref_reconvolution == 2
            obj.p_ref_lifetime_err = libpointer('doublePtr', zeros(obj.I0_size));
        end
    end



    obj.p_chi2 = libpointer('doublePtr', zeros(obj.I0_size));
    obj.p_ierr = libpointer('int32Ptr', zeros(obj.globals_size));
    %catch e %#ok
    %    obj.clear_temp_vars();
    %    err = -1005;
    %    return;
    %end
    
    obj.start_time = tic;
   
    obj.call_fitting_lib(roi_mask,selected);
    
                   
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