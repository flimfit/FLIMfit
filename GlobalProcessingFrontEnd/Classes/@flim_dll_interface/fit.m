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
            n_im = sum(obj.data_series.use);
            obj.fit_result.init(n_im,obj.fit_params.use_memory_mapping);
        end
        obj.fit_result.binned = obj.bin;
        obj.fit_result.names = obj.data_series.names;
                
    end

    p = obj.fit_params;
    d = obj.data_series;
    
    obj.use_image_irf = d.has_image_irf && ~obj.bin && p.image_irf_mode == 1;
    
    if p.global_fitting < 2 || p.global_variable == 0
        if false && d.lazy_loading && p.split_fit
            obj.n_rounds = ceil(d.num_datasets/p.n_thread);

            idx = 1:d.num_datasets;
            
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
     
    sel = 1:d.num_datasets;
    
    if obj.bin
        datasets = (sel == selected);
        obj.n_rounds = 1;
    end

    sel = sel(datasets);
    
    if d.lazy_loading
        d.load_selected_files(sel);
    end    

    
    md = obj.data_series.metadata;
    
    fields = fieldnames(md);
    for i=1:length(fields)
        f = md.(fields{i});
        md.(fields{i}) = f(d.use);
    end
    
    obj.fit_result.metadata = md;
    obj.fit_result.smoothing = (2*d.binning+1)^2;
    

    if obj.bin
        obj.datasets = 1;
        use = 1;
    else
        obj.datasets = sel;
        use = datasets(d.loaded);
    end
    
    obj.use = use;
        
    obj.im_size = [d.height d.width];
   
    obj.p_use = libpointer('int32Ptr',use);
    
    obj.p_tau_guess = libpointer('doublePtr',p.tau_guess);
    obj.p_tau_min = libpointer('doublePtr',p.tau_min);
    obj.p_tau_max = libpointer('doublePtr',p.tau_max);
    
    if obj.use_image_irf
        obj.p_irf = libpointer('doublePtr', d.tr_image_irf);
    else
        obj.p_irf = libpointer('doublePtr', d.tr_irf);
    end
    
    if ~isempty(d.t0_image) && p.image_irf_mode == 2
        obj.p_t0_image = libpointer('doublePtr', d.t0_image);
    else
        obj.p_t0_image = [];
    end
    
    obj.p_t_int = libpointer('doublePtr',d.tr_t_int);
    obj.p_t_irf = libpointer('doublePtr', d.tr_t_irf);
    obj.p_fixed_beta = libpointer('doublePtr',p.fixed_beta / sum(p.fixed_beta));
    obj.p_E_guess = libpointer('doublePtr',p.fret_guess);
    obj.p_theta_guess = libpointer('doublePtr',p.theta_guess);
    obj.p_global_beta_group = libpointer('int32Ptr',p.global_beta_group);
    
    obj.p_tvb_profile = libpointer('doublePtr',d.tr_tvb_profile);

    if ~d.use_memory_mapping
        obj.p_data = libpointer('singlePtr', d.data_series_mem);
    end

    
    obj.start_time = tic;
   
    err = obj.call_fitting_lib(roi_mask,selected);
    
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