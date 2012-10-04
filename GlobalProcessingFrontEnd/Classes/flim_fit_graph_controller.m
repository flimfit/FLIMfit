classdef flim_fit_graph_controller < abstract_plot_controller
   
    properties
        graph_independent_popupmenu;
        ind_param;
        error_type_popupmenu;
        error_calc_popupmenu;
    end
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.graph_axes,handles.graph_dependent_popupmenu,true);            
            assign_handles(obj,handles);

            set(obj.graph_independent_popupmenu,'Callback',@obj.ind_param_select_update);
            
            set(obj.error_type_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.error_calc_popupmenu,'Callback',@(~,~,~) obj.update_display);
            
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
                
                obj.ind_param_select_update([],[]);  
            end
        end
        
        
        function draw_plot(obj,ax,param)
            
            error_type = get(obj.error_type_popupmenu,'Value');
            error_calc = get(obj.error_calc_popupmenu,'Value');

            if obj.fit_controller.has_fit && ~isempty(obj.ind_param) && obj.cur_param > 0

                f = obj.fit_controller;  
                r = f.fit_result;
                sel = obj.fit_controller.selected;
                
                err_name = [param '_err'];

                if ~any(strcmp(obj.param_list,err_name))
                    err_name = [];
                end

                
                
                % Reject images with no associated data (i.e. empty images)
                %isparam = cellfun(@(x)isfield(x,param),r.image_stats);
                %isparam = isparam(sel);
                %sel = sel(isparam);
                
                
                % Get values for the selected parameter
                md = r.metadata.(obj.ind_param);

                % Reject images which don't have metadata for this parameter
                empty = cellfun(@isempty,md(sel));
                sel = sel(~empty);
                
                
                md = md(sel);
                   
                % Determine if we've got a numeric parameter
                var_is_numeric = all(cellfun(@isnumeric,md));
                
                % Determine unique parameters
                if var_is_numeric
                    md = cell2mat(md);
                    x_data = md;
                    x_data = unique(x_data);
                    x_data = sort(x_data);
                else
                    numeric = cellfun(@isnumeric,md);
                    
                    md(numeric) = cellfun(@num2str,md(numeric),'UniformOutput',false);
                    
                    x_data = unique(md);
                    x_data = sort_nat(x_data);
                end

                y_scatter = [];
                x_scatter = [];
                err = [];
                for i=1:length(x_data)
                    y = 0; yv = 0; yn = 0; e = 0; ym = [];
                    
                    % Determine which images to include
                    if var_is_numeric   
                        x_sel = md == x_data(i);
                    else
                        x_sel = strcmp(md,x_data{i});
                    end
                    
                    x_sel = sel(x_sel);
                    
                    ym = NaN(size(x_sel));
                    ys = NaN(size(x_sel));
                    yn = NaN(size(x_sel));
                    
                    idx = 1;
                    for j=x_sel

                        n = r.image_size{j};
                        if n > 0

                            ym(idx) = r.image_mean{j}(param);
                            ys(idx) = r.image_std{j}(param);
                            yn(idx) = n;
                        
                            idx = idx + 1;
                        end
                        %if ~isempty(err_name)
                        %    e = e + r.image_stats{j}.(err_name).mean * n;
                        %end
                    end
                        
                    y_scatter = [y_scatter ym];
                    x_scatter = [x_scatter ones(size(ym))*i];
                    
                    [M S N] = combine_stats(ym,ys,yn);
                    
                    y_data(i) = M;
                    y_err(i) = S / sqrt(N/r.smoothing); % 95% conf interval ~2*standard error 
                    y_std(i) = S;
                    y_img_std(i) = std(ym);
                    y_img_err(i) = y_img_std(i) / sqrt(length(ym));
                    y_n(i) = N;
                    %err(i) = e/yn;

                    %y_mean_data(i) = nanmean(ymask);

                end

                %if ~all(err==0) && ~all(isnan(err))
                %    y_err = err;
                %end

                if error_type == 1 % std
                    if error_calc == 1 % pixel
                        err = y_std;
                    else
                        err = y_img_std;
                    end
                else % 95% conf
                    if error_calc == 1 % pixel
                        err = y_err;
                    else
                        err = y_img_err; 
                    end
                end
                    
                
                if var_is_numeric
                    errorbar(ax,x_data,y_data,err,'or-','LineWidth',2,'MarkerSize',6,'MarkerFaceColor','r');
                    hold(ax,'on');
                    plot(ax,x_data(x_scatter),y_scatter,'x','MarkerSize',5);
                    cell_x_data = num2cell(x_data);
                else
                    errorbar(ax,y_data,err,'or-','LineWidth',2,'MarkerSize',6,'MarkerFaceColor','r');
                    hold(ax,'on')
                    plot(ax,x_scatter,y_scatter,'x','MarkerSize',5);
                    set(ax,'XTick',1:length(y_data));
                    set(ax,'XTickLabel',x_data);
                    cell_x_data = x_data;
                end

                %{
                fig = obj.window;
                
                data = struct('graph_axes',ax,'x_data',x_data,'y_data',y_data);
                
                datacursormode(fig,'on');
                dcm_obj = datacursormode(fig);
                set(dcm_obj,'UpdateFcn',@(p1,p2) data_cursor(data,p1,p2))
                datacursormode(fig,'on');
                %}
                
                hold(ax,'off');

                lims = f.get_cur_lims(param);

                if isnan(lims(1)) || lims(1) > min(y_data);
                    lims(1) = 0.9*min(y_data);
                end
                if isnan(lims(2)) || lims(2) < max(y_data);
                    lims(2) = 1.1*max(y_data);
                end
                set(ax,'YLim',lims);
                
                %set(ax,'XLim',[nanmin(x_data) nanmax(x_data)])
                
                obj.raw_data = [cell_x_data; num2cell(y_data); num2cell(y_std); num2cell(y_err); num2cell(y_img_std); num2cell(y_img_err); num2cell(y_n)]';
                
                obj.raw_data = [{obj.ind_param param 'pixel std' 'pixel 95% conf' 'image std' 'image 95% conf' 'count'}; obj.raw_data]; 
                
                latex_param = r.params{param};
                latex_param = strrep(latex_param,'mean_tau','mean tau');
                latex_param = strrep(latex_param,'w_mean','weighted mean');
                
                ylabel(ax,latex_param);
                xlabel(ax,obj.ind_param);
  
            else
                cla(ax);
            end
            
        end


        
    end
    
    
end

