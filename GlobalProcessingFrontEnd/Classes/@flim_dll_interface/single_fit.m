function [err,f] = single_fit(obj, data_series, mask, dataset_selected, fit_params)

    p = fit_params;
    d = data_series;
    
    n_datasets = d.num_datasets;
    datasets = 1:n_datasets;
    
    obj.datasets = datasets;

    obj.fit_in_progress = true;

    obj.fit_params = fit_params;
    obj.data_series = data_series;

    n_group = 1;            
    obj.n_regions = 1;
    obj.n_regions_total = 1;

    n_px = 1;
    obj.globals_size = 1;

    obj.I0_size = [1 1];
    obj.tau_size = [p.n_exp 1 1];

    obj.n_group = n_group;

    decay = data_series.get_roi(mask,dataset_selected);
        
    obj.p_tau = libpointer('doublePtr', zeros(obj.tau_size));
    obj.p_beta = libpointer('doublePtr', zeros(obj.tau_size));
    obj.p_dk = libpointer('doublePtr',zeros(obj.I0_size));
    obj.p_I0 = libpointer('doublePtr', zeros(obj.I0_size));
    obj.p_t0 = libpointer('doublePtr', zeros(obj.I0_size));
    obj.p_offset = libpointer('doublePtr',zeros(obj.I0_size));
    obj.p_scatter = libpointer('doublePtr',zeros(obj.I0_size));

    obj.p_chi2 = libpointer('doublePtr', zeros(obj.globals_size));
    obj.p_ierr = libpointer('int32Ptr', zeros(obj.globals_size));

    
    fixed_beta = p.fixed_beta / sum(p.fixed_beta);
    
    tic;
    
    err = calllib(obj.lib_name,'FLIMGlobalFit', ...
                        n_group, n_px, obj.n_regions, p.global_fitting, ...
                        decay, 0, obj.mask, ...
                        length(d.tr_t), d.tr_t, length(d.tr_irf), d.tr_t_irf, d.tr_irf, ...
                        p.n_exp, p.n_fix, p.tau_guess, ...
                        p.fit_beta, fixed_beta, ...
                        p.fit_t0, p.t0, p.fit_offset, p.offset, ...
                        p.fit_scatter, p.scatter, ...
                        0, 0, ...
                        p.pulsetrain_correction, 1/p.rep_rate, ...
                        p.ref_reconvolution, p.ref_lifetime, p.fitting_algorithm, ...
                        obj.p_tau, obj.p_I0, obj.p_beta, obj.p_dk, ...
                        obj.p_t0, obj.p_offset, obj.p_scatter, ...
                        obj.p_chi2, obj.p_ierr, p.n_thread, false, false, 0);
                    
    f = flim_fit_result();
    
    % get results
    f.beta = reshape(obj.p_beta.Value,obj.tau_size);
    clear obj.p_beta;
    
    f.tau = reshape(obj.p_tau.Value,obj.tau_size);
    clear obj.p_tau;
    
    f.I0 = reshape(obj.p_I0.Value,obj.I0_size);
    clear obj.p_I0;
    
    f.offset = reshape(obj.p_offset.Value,obj.I0_size);
    clear obj.p_offset;
    
    f.scatter = reshape(obj.p_scatter.Value,obj.I0_size);
    clear obj.p_scatter;
    
    f.t0 = reshape(obj.p_t0.Value,obj.I0_size);
    clear obj.p_t0;
    
    f.chi2 = reshape(obj.p_chi2.Value,obj.globals_size);
    f.ierr = reshape(obj.p_ierr.Value,obj.globals_size);

    
end