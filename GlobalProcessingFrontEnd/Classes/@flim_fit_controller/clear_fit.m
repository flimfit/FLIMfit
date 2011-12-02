function clear_fit(obj)

    obj.has_fit = false;

    obj.fit_result = flim_fit_result();
    
    set(obj.results_table,'ColumnName',[]);
    set(obj.results_table,'Data',[]);    

    set(obj.progress_table,'ColumnName',[]);
    set(obj.progress_table,'Data',[]);    

    notify(obj,'fit_updated');

end