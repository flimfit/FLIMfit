function update_table(obj)
    if ishandle(obj.results_table)

        if ishandle(obj.table_stat_popupmenu)
            stat = get(obj.table_stat_popupmenu,'Value');
            stat = obj.fit_result.stat_names{stat};
        else 
            stat = 'mean';
        end

        [data,column_headers] = obj.get_table_data(stat);

        set(obj.results_table,'ColumnName','numbered');
        set(obj.results_table,'RowName',column_headers);
        set(obj.results_table,'Data',data);

        set(obj.progress_table,'RowName',column_headers(1:4));
        set(obj.progress_table,'Data',data(1:4,:));
    end
end