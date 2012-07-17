function filter_table_updated(obj,~,~)

    data = get(obj.filter_table,'Data');

    sel = true(1,obj.fit_result.n_results);
    
    md = obj.fit_result.metadata;
    
    for i=1:size(data,1)
       
        if all(cellfun(@isempty,data(i,:)))==0 && ~strcmp(data{i,1},'-')
            
            field = data{i,1};
            op_str = data{i,2};
            val = data{i,3};
            
            m = md.(field);
            var_is_numeric = all(cellfun(@isnumeric,m));

            if var_is_numeric
                
                m = cell2mat(m);
                val = str2double(val);
                
                switch op_str
                    case '='
                        op = @eq;
                    case '!='
                        op = @ne;
                    case '<'
                        op = @lt;
                    case '>'
                        op = @gt;
                    otherwise
                        op = [];
                end
                
                if ~isempty(op)
                    sel = sel & op(m,val);
                end
            else
                
                switch op_str
                    case '='
                        op = @strcmp;
                    case '!='
                        op = @(x,y) (1-strcmp(x,y));
                    otherwise
                        op = [];
                end
                
                if ~isempty(op)
                    sel = sel & cellfun(@(x)op(val,x),m);
                end
                
            end
            
           
            
        end
        
    end

    new_selected = 1:obj.fit_result.n_results;
    new_selected = new_selected(sel);

    changed = length(new_selected)~=length(obj.selected) || ~all(new_selected==obj.selected);
       
    obj.selected = new_selected;
    
    if changed
        notify(obj,'fit_display_updated');
    end
end