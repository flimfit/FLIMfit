function store_fit_result(obj, session)

    
    if obj.has_fit
        res = obj.fit_result;
        
        n_results = res.get_n_results();
        params = res.fit_param_list()
        n_params = length(params)
        for dataset = 1:n_results
            for p = 1:n_params
                par = params{p}
                param_array(p,:,:) = res.get_image(dataset, par);
            end
        end
        
        % tbd write to file
            
    end
    
end