function update_progress(obj,~,~)
    
    p = obj.fit_params;

    group = zeros(1,p.n_thread);
    n_completed = zeros(1,p.n_thread);
    iter = zeros(1,p.n_thread);
    chi2 = zeros(1,p.n_thread);
    progress = 0.0;
    
    [finished, obj.progress_cur_group, obj.progress_n_completed, obj.progress_iter, obj.progress_chi2, obj.progress] ...
     = calllib(obj.lib_name,'FLIMGetFitStatus', obj.dll_id, group, n_completed, iter, chi2, progress); 
    
    if finished
        obj.get_return_data();
        if obj.fit_round > obj.n_rounds || ~obj.fit_in_progress
            obj.fit_in_progress = false;
            stop(obj.fit_timer);
            delete(obj.fit_timer);
            notify(obj,'fit_completed');
        else
            obj.fit();
        end
    else
        notify(obj,'progress_update');
    end
end