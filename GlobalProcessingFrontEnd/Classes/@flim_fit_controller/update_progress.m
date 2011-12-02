function update_progress(obj,~,~)
    
    if obj.fit_in_progress

        p = obj.fit_params;

        [progress, n_completed, cur_group, iter, chi2] = obj.dll_interface.get_progress();

        if ishandle(obj.wait_handle)
            waitbar(progress,obj.wait_handle);
        end

        table_data = [double((1:p.n_thread)); double(n_completed); ...
                      double(cur_group); double(iter); double(chi2)];



        set(obj.progress_table,'Data',table_data);
    end
    
end