function get_return_data(obj)

    f = obj.fit_result;
    p = obj.fit_params;
    d = obj.data_series;
    
    f.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(f.t_exec)]);
        
    if obj.bin
        datasets = 1;
        %sz = [1 1];
    else
        datasets = obj.datasets;
        %sz = [d.height d.width];
    end
        
    p_mask = libpointer('uint8Ptr', []);
        
    ierr = reshape(obj.p_ierr.Value,obj.globals_size);
    clear obj.p_ierr
    
    % Get param names
    
    p_n_output = libpointer('int32Ptr',0);
    ptr = calllib(obj.lib_name,'GetOutputParamNames',obj.dll_id, p_n_output);
    
    n_output = p_n_output.Value;
    param_names = cell(1,n_output);
    for i=1:n_output
        param_names(i) = ptr.Value;
        ptr = ptr + 1;
    end
    
    f.set_param_names(param_names);

    for i=1:n_output
        f.default_lims{i} = [0 1000];
    end
    
    wh = waitbar(0, 'Processing fit results...'); %,'CreateCancelBtn','setappdata(gcbf,''canceling'',1);');
    
    setappdata(wh,'canceling',0);
    
    % Get results for each image
    for i = 1:length(datasets)
        
        im = datasets(i);
                
        if (obj.n_regions(im) > 0) % && obj.use(i))
            % Retrieve results
            
            p_n_regions = libpointer('int32Ptr',0);
            p_regions = libpointer('int32Ptr',zeros(n_output,255)); 
            p_region_size = libpointer('int32Ptr',zeros(n_output,255)); 
            p_mean = libpointer('singlePtr',zeros(n_output,255));
            p_std = libpointer('singlePtr',zeros(n_output,255));
            
            err = calllib(obj.lib_name,'GetAverageResults',obj.dll_id, im-1, p_mask, p_n_regions, p_regions, p_region_size, p_mean, p_std);
            
            n_regions = p_n_regions.Value;
            regions = p_regions.Value;
            regions = regions(1:n_regions);
            region_size = p_region_size.Value;
            region_size = region_size(1:n_regions);
            
            param_mean = reshape(p_mean.Value,[n_output,255]);
            param_std = reshape(p_std.Value,[n_output,255]);
            param_mean = param_mean(:,1:n_regions);
            param_std = param_std(:,1:n_regions);
            
            f.set_results(im,regions,region_size,param_mean,param_std);
            
            disp(param_mean);
        end


     
        if mod(i,10)
            waitbar(i/length(datasets),wh);
        end
    end
            
    if ishandle(wh)
        delete(wh);
    end
    
    clear p_chi2;
    clear p_tau p_tau_err p_beta p_beta_err;
    clear p_ref_lifetime;
    clear p_ref_lifetime_err;
    clear p_tvb_err tvb_err
    clear p_tvb
    clear p_theta p_theta_err p_r p_E p_E_err p_gamma p_scatter p_scatter_err clear p_offset_err p_offset
    clear p_I0 p_E_err;

    f.smoothing = (2*d.binning+1)^2;
    
    for i=1:length(datasets)
       if p.global_fitting < 2
           r_start = 1+sum(obj.n_regions(1:i-1));
           r_end = r_start + obj.n_regions(i)-1;
       else
           r_start = 1;
           r_end = obj.n_regions(1);
       end
           
       if r_end < r_start
           f.ierr(datasets(i)) = 0;
           f.iter(datasets(i)) = 0;
           f.success(datasets(i)) = 100;
       else
           if p.global_fitting == 0
               ierrd = ierr(:,:,i);
           elseif p.global_fitting == 1
               ierrd = ierr(r_start:r_end);
           else
               ierrd = ierr;
           end

           ierrs = double(ierrd(ierrd<0));
           if isempty(ierrs)
               ierrs = 0;
           else
               ierrs = mode(ierrs);
           end

           f.ierr(datasets(i)) = ierrs;
           f.iter(datasets(i)) = sum(ierrd(ierrd>=0));
           f.success(datasets(i)) = sum(ierrd(:)>=0)/length(ierrd(:)) * 100;
           
       end

    end
    clear ierr       
end