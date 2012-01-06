function clear_fit(obj)

    had_fit = obj.has_fit;
    obj.has_fit = false;

    obj.fit_result = flim_fit_result();
    
    set(obj.results_table,'ColumnName',[]);
    set(obj.results_table,'Data',[]);    

    set(obj.progress_table,'ColumnName',[]);
    set(obj.progress_table,'Data',[]);    

    if had_fit
        notify(obj,'fit_updated');
    end
end