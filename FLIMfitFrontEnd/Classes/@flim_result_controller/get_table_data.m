
function [data, row_headers] = get_table_data(obj, stat)

    r = obj.fit_result;
    if ~isempty(stat)
        data = table2array(r.region_stats.(stat))';
        row_headers = r.region_stats.(stat).Properties.VariableNames;
    end

end
