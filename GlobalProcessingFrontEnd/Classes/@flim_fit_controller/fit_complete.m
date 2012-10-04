function fit_complete(obj,~,~)
    
    obj.fit_result = obj.dll_interface.fit_result;
    
    [obj.param_table, obj.param_table_headers] = obj.dll_interface.get_param_list();
    
    obj.dll_interface.fit_result = [];
    
    obj.display_fit_end();

    obj.update_table();

    obj.has_fit = true;
    obj.fit_in_progress = false;
    
    obj.update_progress([],[]);
    
    t_exec = toc(obj.start_time);    
    disp(['Total execution time: ' num2str(t_exec)]);
    
    obj.selected = 1:obj.fit_result.n_results;
    
    obj.update_filter_table();
    obj.update_list();
    obj.update_display_table();
   
    try
    notify(obj,'fit_updated');    
    catch ME
        getReport(ME)
    end
    notify(obj,'fit_completed');    
    
    
    
    if obj.refit_after_return
        obj.refit_after_return = false;
        obj.fit(true);
    end

    
end

