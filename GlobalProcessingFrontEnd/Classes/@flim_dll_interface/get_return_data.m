function get_return_data(obj)

    f = obj.fit_result;
    
    f.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(f.t_exec)]);
        
    if obj.bin
        datasets = 1;
    else
        datasets = obj.datasets;
    end
        
    p_mask = libpointer('uint8Ptr', []);
        
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

    p_n_regions = libpointer('int32Ptr',0);
    p_regions = libpointer('int32Ptr',zeros(n_output,255)); 
    p_region_size = libpointer('int32Ptr',zeros(n_output,255)); 
    p_mean = libpointer('singlePtr',zeros(n_output,255));
    p_std = libpointer('singlePtr',zeros(n_output,255));
    p_pct_01 = libpointer('singlePtr',zeros(n_output,255));
    p_pct_99 = libpointer('singlePtr',zeros(n_output,255));
    p_success = libpointer('singlePtr',zeros(n_output,255)); 
    p_iterations = libpointer('int32Ptr',zeros(n_output,255)); 

    
    % Get results for each image
    for i = 1:length(datasets)
        
        im = datasets(i);
                            

        err = calllib(obj.lib_name,'GetImageStats',obj.dll_id, im-1, p_mask, p_n_regions, ...
                      p_regions, p_region_size, p_success, p_iterations, p_mean, p_std, p_pct_01, p_pct_99);

        n_regions = p_n_regions.Value;
        
        regions = p_regions.Value;
        regions = regions(1:n_regions);
        region_size = p_region_size.Value;
        region_size = region_size(1:n_regions);

        iterations = p_iterations.Value;
        iterations = iterations(1:n_regions);

        success = p_success.Value;
        success = success(1:n_regions);
        
        param_mean = reshape(p_mean.Value,[n_output,255]);
        param_std = reshape(p_std.Value,[n_output,255]);
        param_mean = param_mean(:,1:n_regions);
        param_std = param_std(:,1:n_regions);
        
        param_pct_01 = reshape(p_pct_01.Value,[n_output,255]);
        param_pct_99 = reshape(p_pct_99.Value,[n_output,255]);
        param_pct_01 = param_pct_01(:,1:n_regions);
        param_pct_99 = param_pct_99(:,1:n_regions);

        f.set_results(i,regions,region_size,success,iterations,param_mean,param_std,param_pct_01,param_pct_99);
            
    end
            

    %{
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
    %}
end