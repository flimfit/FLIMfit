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
    
    
    obj.use_image_irf = d.has_image_irf && ~obj.bin; %&& p.global_fitting == 0
    obj.use_image_irf = false;
    
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
     
    obj.datasets = sel;

    if obj.bin
        use = 1;
    else
        use = datasets(d.loaded);
    end
    
    obj.n_im = sum(use);
    obj.use = use;
    
    width = d.width;
    height = d.height;

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
        
        
        if ~isempty(d.seg_mask)
            
            mask = d.seg_mask;
            
            obj.n_regions = reshape(mask,[size(mask,1)*size(mask,2) size(mask,3)]);
            obj.n_regions = squeeze(max(obj.n_regions,[],1));
        else
            mask = [];
            obj.n_regions = ones([1 d.n_datasets]);
        end
        
        obj.n_regions_total = sum(obj.n_regions);

        
        switch p.global_fitting
            case 0
                obj.n_group = width * height * obj.n_im;            
                %{
                if ~isempty(mask)
                    obj.n_regions = mask;
                    obj.n_regions_total = max(mask(:));
                else
                    obj.n_regions = ones([1 obj.n_im]);
                   obj.n_regions_total = obj.n_im;
                end
                %}
                obj.n_regions_total = obj.n_im;
                obj.n_px = 1;
                obj.globals_size = [height width obj.n_im];
                
                if p.use_phase_plane_estimation         
                    est_decay = d.data_series;
                end


            case 1 %global_mode.image
                obj.n_group = n_im;
               
                obj.globals_size = [1 obj.n_regions_total];

                obj.n_px = width * height;
                
                if p.use_phase_plane_estimation         
                    est_decay = zeros(d.n_tr_t,obj.n_im);
                    
                    for i=1:obj.n_im
                        masked = d.get_roi([],i);
                        sz = size(masked);
                        decay = nansum(reshape(masked,[sz(1) prod(sz(2:end))]),2);
                        est_decay(:,i) = decay;
                    end
                end


            case 2 %global_mode.dataset
                obj.n_group = 1;
                %{
                if ~isempty(mask)
                    obj.n_regions = max(mask(:));
                else
                    obj.n_regions = 1;
                end
                obj.n_regions_total = obj.n_regions;
                %}
                obj.n_px = width * height * obj.n_im;
                obj.globals_size = [1 obj.n_regions_total];
                
                if p.use_phase_plane_estimation          
                    est_decay = zeros(d.n_t,1);
                    
                    for i=1:obj.n_im
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
       
    obj.n_regions = double(obj.n_regions);
   
    obj.p_use = libpointer('int32Ptr',use);
    
    obj.p_tau_guess = libpointer('doublePtr',p.tau_guess);
    obj.p_tau_min = libpointer('doublePtr',p.tau_min);
    obj.p_tau_max = libpointer('doublePtr',p.tau_max);
    
    if obj.use_image_irf
        obj.p_irf = libpointer('doublePtr', d.tr_image_irf);
    else
        obj.p_irf = libpointer('doublePtr', d.tr_irf);
    end
    
    if ~isempty(d.t0_image) 
        obj.p_t0_image = libpointer('doublePtr', d.t0_image);
    else
        obj.p_t0_image = [];
    end
    
    obj.p_t_int = libpointer('doublePtr',d.tr_t_int);
    obj.p_t_irf = libpointer('doublePtr', d.tr_t_irf);
    obj.p_fixed_beta = libpointer('doublePtr',p.fixed_beta / sum(p.fixed_beta));
    obj.p_E_guess = libpointer('doublePtr',p.fret_guess);
    obj.p_theta_guess = libpointer('doublePtr',p.theta_guess);

    obj.p_tvb_profile = libpointer('doublePtr',d.tr_tvb_profile);

    if ~d.use_memory_mapping
        obj.p_data = libpointer('singlePtr', d.data_series_mem);
    end


    obj.p_ierr = libpointer('int32Ptr', zeros(obj.globals_size));
    
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