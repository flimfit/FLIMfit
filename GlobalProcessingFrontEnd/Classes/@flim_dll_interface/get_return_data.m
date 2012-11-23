function get_return_data(obj)

    r = obj.fit_result;
    d = obj.data_series;
    
    % Get timing information
    r.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(r.t_exec)]);
        
  
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
    p_median = libpointer('singlePtr',zeros(n_output,255));
    p_q1 = libpointer('singlePtr',zeros(n_output,255));
    p_q2 = libpointer('singlePtr',zeros(n_output,255));
    
    p_pct_01 = libpointer('singlePtr',zeros(n_output,255));
    p_pct_99 = libpointer('singlePtr',zeros(n_output,255));
    p_success = libpointer('singlePtr',zeros(n_output,255)); 
    p_iterations = libpointer('int32Ptr',zeros(n_output,255)); 
    p_mask = libpointer('uint8Ptr', []);

    
    
    
    keep = true(size(obj.datasets));
    idx = 1;
    % Get results for each image
    for i = 1:length(obj.datasets)
        
        im = obj.datasets(i);
                            

        err = calllib(obj.lib_name,'GetImageStats',obj.dll_id, im-1, p_mask, p_n_regions, ...
                      p_regions, p_region_size, p_success, p_iterations, p_mean, p_std, p_median, p_q1, p_q2, p_pct_01, p_pct_99);

        n_regions = p_n_regions.Value;
        
        if n_regions > 0
            
            have_data(i) = 0;
            
            region_size = double(p_region_size.Value);
            region_size = region_size(1:n_regions);

            sel = region_size > 0;
            region_size = region_size(sel);

            regions = double(p_regions.Value);
            regions = regions(sel);
            
            iterations = double(p_iterations.Value);
            iterations = iterations(sel);

            success = double(p_success.Value);
            success = success(sel);

            param_mean = reshape_return(p_mean,sel);
            param_std = reshape_return(p_std,sel);
            param_median = reshape_return(p_median,sel);
            param_q1 = reshape_return(p_q1,sel);
            param_q2 = reshape_return(p_q2,sel);
            param_pct_01 = reshape_return(p_pct_01,sel);
            param_pct_99 = reshape_return(p_pct_99,sel);

            r.set_results(idx,regions,region_size,success,iterations,param_mean,param_std,param_median,param_q1,param_q2,param_pct_01,param_pct_99);
            idx = idx+1;
        else
            keep(i) = false;
        end
        
    end
    
    obj.datasets = obj.datasets(keep);
    
    % Get metadata for the datasetes we've just fit
    md = obj.data_series.metadata;
    fields = fieldnames(md);
    for i=1:length(fields)
        f = md.(fields{i});
        md.(fields{i}) = f(obj.datasets);
    end
    
    obj.fit_result.metadata = md;
    
    function data = reshape_return(data,sel)
        data = reshape(double(data.Value),[n_output,255]);
        s = false([1,255]);
        s(1:length(sel)) = sel;
        data = data(1:n_output,s);
        
    end
    
end