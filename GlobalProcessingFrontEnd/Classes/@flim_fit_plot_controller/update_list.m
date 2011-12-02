 function update_list(obj)
        if (obj.fit_controller.has_fit)

            r = obj.fit_controller.fit_result;
            
            old_names = obj.plot_names;
            obj.plot_names = r.fit_param_list();
            obj.default_lims = r.default_lims();
            
            names = obj.plot_names;
            n_items = length(names);
            
            for i=1:n_items
                if ~any(strcmp(old_names,names{i}))
                    obj.display_normal.(names{i}) = false;
                    obj.display_merged.(names{i}) = false;
                    obj.auto_lim.(names{i}) = false;
                    obj.plot_lims.(names{i}) = obj.default_lims.(names{i});
                end
            end
            
            for i=1:length(old_names)
                if ~any(strcmp(obj.plot_names,old_names{i}))
                    obj.display_normal = rmfield(obj.display_normal,old_names{i});
                    obj.display_merged = rmfield(obj.display_merged,old_names{i});
                    obj.auto_lim = rmfield(obj.auto_lim,old_names{i});
                    obj.plot_lims = rmfield(obj.plot_lims,old_names{i});
                end
            end   
        end
            
 end