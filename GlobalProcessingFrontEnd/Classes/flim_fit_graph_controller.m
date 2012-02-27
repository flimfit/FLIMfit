classdef flim_fit_graph_controller < abstract_plot_controller
   
    properties
        graph_independent_popupmenu;
        ind_param;
    end
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.graph_axes,handles.graph_dependent_popupmenu,true);            
            assign_handles(obj,handles);

            set(obj.graph_independent_popupmenu,'Callback',@obj.ind_param_select_update);
            
            obj.update_display();
        end
        
        function ind_param_select_update(obj,~,~)
            idx = get(obj.graph_independent_popupmenu,'Value');
            r = obj.fit_controller.fit_result;            
            ind_vars = fieldnames(r.metadata);
            obj.ind_param = ind_vars{idx}; 
            
            obj.update_display();
        end
        
        function plot_fit_update(obj)
            if obj.fit_controller.has_fit
                
                r = obj.fit_controller.fit_result;            
                ind_vars = fieldnames(r.metadata);
                
                set(obj.graph_independent_popupmenu,'String',ind_vars);
                
                obj.ind_param_select_update();  
            end
        end
        
        
        function draw_plot(obj,ax,param)

            if obj.fit_controller.has_fit && ~isempty(obj.ind_param) && ~isempty(obj.cur_param)

                r = obj.fit_controller.fit_result;     

                err_name = [param '_err'];

                if ~any(strcmp(obj.param_list,err_name))
                    err_name = [];
                end

                n_im = length(r.images);


                md = r.metadata.(obj.ind_param);

                empty = cellfun(@isempty,md);
                
                var_is_numeric = all(cellfun(@isnumeric,md(~empty)));

                if var_is_numeric
                    x_data = cell2mat(md(~empty));
                    x_data = unique(x_data);
                    x_data = sort(x_data);
                else
                    x_data = unique(md(~empty));
                    x_data = sort(x_data);
                end

                for i=1:length(x_data)
                    y = 0; yv = 0; yn = 0; e = 0; 
                    for j=1:n_im
                        if ~empty(j) ... 
                            && ((var_is_numeric && md{j} == x_data(i)) || (~var_is_numeric && strcmp(md{j},x_data{i}))) ...
                            && isfield(r.image_stats{j},param)
  
                            n = r.image_stats{j}.(param).n;
                            if n > 0
                                y = y + r.image_stats{j}.(param).mean * n; 
                                yv = yv + (r.image_stats{j}.(param).std)^2*n;
                                yn = yn + r.image_stats{j}.(param).n;
                            end
                            
                            if ~isempty(err_name)
                                e = e + r.image_stats{j}.(err_name).mean * n;
                            end

                        end
                    end
                    y_data(i) = y/yn;
                    y_err(i) = 2 * sqrt(yv/yn) / sqrt(yn); % 95% conf interval ~2*standard error 
                    y_std(i) = sqrt(yv/yn);
                    y_n(i) = yn;
                    err(i) = e/yn;

                    %y_mean_data(i) = nanmean(ymask);

                end

                if ~all(err==0) && ~all(isnan(err))
                    y_err = err;
                end

                if var_is_numeric
                    errorbar(ax,x_data,y_data,y_err,'o-');
                    cell_x_data = num2cell(x_data);
                else
                    errorbar(ax,y_data,y_err,'o-');
                    set(ax,'XTick',1:length(y_data));
                    set(ax,'XTickLabel',x_data);
                    cell_x_data = x_data;
                end

                if isfield(r.default_lims,param)
                    lims = r.default_lims.(param);

                    if isnan(lims(1)) || lims(1) > min(y_data);
                        lims(1) = 0.9*min(y_data);
                    end
                    if isnan(lims(2)) || lims(2) < max(y_data);
                        lims(2) = 1.1*max(y_data);
                    end
                    set(ax,'YLim',lims);
                end
                
                obj.raw_data = [cell_x_data; num2cell(y_data); num2cell(y_std); num2cell(y_err); num2cell(y_n)]';
                
                obj.raw_data = [{obj.ind_param param 'std' '95% conf' 'count'}; obj.raw_data]; 
                
                latex_param = param;
                latex_param = strrep(latex_param,'mean_tau','mean tau');
                latex_param = strrep(latex_param,'w_mean','weighted mean');
                
                ylabel(ax,latex_param);
                xlabel(ax,obj.ind_param);
            end
            
        end


        
    end
    
    
end