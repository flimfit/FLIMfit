classdef flim_fit_graph_controller < abstract_plot_controller
   
    properties
        graph_independent_popupmenu;
        ind_param;
    end
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.graph_axes,handles.graph_dependent_popupmenu);            
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

            if obj.fit_controller.has_fit && ~isempty(obj.ind_param)

                r = obj.fit_controller.fit_result;     

                %mask = obj.roi_controller.roi_mask;

                err_name = [param '_err'];

                if ~any(strcmp(obj.param_list,err_name))
                    err_name = [];
                end

                n_im = length(r.images);


                md = r.metadata.(obj.ind_param);

                var_is_numeric = all(cellfun(@isnumeric,md));

                if var_is_numeric
                    x_data = cell2mat(md);
                    x_data = unique(x_data);
                    x_data = sort(x_data);
                else
                    x_data = unique(md);
                    x_data = sort(x_data);
                end

                for i=1:length(x_data)
                    y = 0; yv = 0; yn = 0; e = 0; ymask = [];
                    for j=1:n_im
                        if ((var_is_numeric && md{j} == x_data(i)) || (~var_is_numeric && strcmp(md{j},x_data{i}))) && isfield(r.image_stats{j},param)
  
                            n = r.image_stats{j}.(param).n;
                            if n > 0
                                y = y + r.image_stats{j}.(param).mean * n; 
                                yv = yv + (r.image_stats{j}.(param).std)^2*n;
                                yn = yn + r.image_stats{j}.(param).n;
                            end
                            
                            if ~isempty(err_name)
                                e = e + r.image_stats{j}.(err_name).mean * n;
                            end

                            %{
                            ym = r.get_image(j,obj.dep);
                            ym = ym(mask);
                            ymask = [ymask; ym];
                            %}

                        end
                    end
                    y_data(i) = y/yn;
                    y_err(i) = 2 * sqrt(yv/yn) / sqrt(yn); % 95% conf interval ~2*standard error 
                    err(i) = e/yn;

                    %y_mean_data(i) = nanmean(ymask);

                end

                if ~all(err==0) && ~all(isnan(err))
                    y_err = err;
                end

                if var_is_numeric
                    errorbar(ax,x_data,y_data,y_err,'o-');
                else
                    errorbar(ax,y_data,y_err,'o-');
                    set(ax,'XTick',1:length(y_data));
                    set(ax,'XTickLabel',x_data);
                end

                ylabel(ax,param);
                xlabel(ax,obj.ind_param);
            end
            
        end


        
    end
    
    
end