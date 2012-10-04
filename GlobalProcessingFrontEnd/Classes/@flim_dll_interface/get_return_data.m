function get_return_data(obj)

    r = obj.fit_result;
    d = obj.data_series;
    
    % Get timing information
    r.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(r.t_exec)]);
        
    
    % Get metadata for the datasetes we've just fit
    md = obj.data_series.metadata;
    fields = fieldnames(md);
    for i=1:length(fields)
        f = md.(fields{i});
        md.(fields{i}) = f(d.use);
    end
    
    obj.fit_result.metadata = md;
    obj.fit_result.smoothing = (2*d.binning+1)^2;
    
        
    % Get param names
    p_n_output = libpointer('int32Ptr',0);
    ptr = calllib(obj.lib_name,'GetOutputParamNames',obj.dll_id, p_n_output);
    
    n_output = p_n_output.Value;
    param_names = cell(1,n_output);
    for i=1:n_output
        param_names(i) = ptr.Value;
        ptr = ptr + 1;
    end
    
    r.set_param_names(param_names);

    % Setup memory to retrieve data
    p_n_regions = libpointer('int32Ptr',0);
    p_regions = libpointer('int32Ptr',zeros(n_output,255)); 
    p_region_size = libpointer('int32Ptr',zeros(n_output,255)); 
    p_mean = libpointer('singlePtr',zeros(n_output,255));
    p_std = libpointer('singlePtr',zeros(n_output,255));
    p_pct_01 = libpointer('singlePtr',zeros(n_output,255));
    p_pct_99 = libpointer('singlePtr',zeros(n_output,255));
    p_success = libpointer('singlePtr',zeros(n_output,255)); 
    p_iterations = libpointer('int32Ptr',zeros(n_output,255)); 
    p_mask = libpointer('uint8Ptr', []);

    
    % Get results for each image
    for i = 1:length(obj.datasets)
        
        im = obj.datasets(i);
                            

        err = calllib(obj.lib_name,'GetImageStats',obj.dll_id, im-1, p_mask, p_n_regions, ...
                      p_regions, p_region_size, p_success, p_iterations, p_mean, p_std, p_pct_01, p_pct_99);

        n_regions = p_n_regions.Value;
        
        if n_regions > 0
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

            r.set_results(i,regions,region_size,success,iterations,param_mean,param_std,param_pct_01,param_pct_99);
        end
        
    end
           
end