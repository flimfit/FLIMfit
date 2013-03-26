classdef flim_fit_graph_controller < abstract_plot_controller
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren

   
    properties
        graph_independent_popupmenu;
        ind_param;
        error_type_popupmenu;
        graph_grouping_popupmenu;
        graph_display_popupmenu;
    end
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.graph_axes,handles.graph_dependent_popupmenu,true);            
            assign_handles(obj,handles);

            set(obj.graph_independent_popupmenu,'Callback',@obj.ind_param_select_update);
            
            set(obj.error_type_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_grouping_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_display_popupmenu,'Callback',@(~,~,~) obj.update_display);
            
            obj.register_tab_function('Plotter');
            obj.update_display();
        end
        
        function ind_param_select_update(obj,~,~)
            idx = get(obj.graph_independent_popupmenu,'Value');
            r = obj.fit_controller.fit_result;            
            ind_vars = fieldnames(r.metadata);
            if idx > length(ind_vars) || idx == 0
                idx = 1;
                set(obj.graph_independent_popupmenu,'Value',idx);
            end
                
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
        
        
        function draw_plot(obj,ax)
            
            prof = get_profile();
            
            export_plot = (nargin == 2);
            if ~export_plot
                ax = obj.plot_handle;
            end
            
            %{
            if export_plot
                f = get(ax,'Parent');
                pos = get(f,'Position');
                
                w = prof.Export.Plotter_Width_Px;
                h = w * 3/4;
                
                pos(3:4) = [w h];
                set(f,'Position',pos);
            end
            %}
            
            param = obj.cur_param;
            
            error_type = get(obj.error_type_popupmenu,'Value');
            grouping = get(obj.graph_grouping_popupmenu,'Value');
            display = get(obj.graph_display_popupmenu,'Value');

            if obj.fit_controller.has_fit && ~isempty(obj.ind_param) && obj.cur_param > 0

                f = obj.fit_controller;  
                r = f.fit_result;
                sel = obj.fit_controller.selected;
                
                err_name = [param '_err'];

                if ~any(strcmp(obj.param_list,err_name))
                    err_name = [];
                end               
                
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
                    
                    ym = [];
                    ys = [];
                    yn = [];
                    
                    idx = 1;
                    for j=x_sel

                        n = r.image_size{j};
                        if n > 0

                            if grouping == 1 || grouping == 3
                                ym(idx) = r.image_stats{j}.('w_mean')(param);
                                ys(idx) = r.image_stats{j}.('w_std')(param);
                                yn(idx) = n;
                            else                                
                                ym = [ym r.region_stats{j}.('w_mean')(param,:)];
                                ys = [ys r.region_stats{j}.('w_std')(param,:)];
                                yn = [yn r.region_size{j}];
                            end
                            
                            idx = idx + 1;
                        end
                        %if ~isempty(err_name)
                        %    e = e + r.image_stats{j}.(err_name).mean * n;
                        %end
                    end
                    
                    yfinite = ~isnan(ym);
                    ym = ym(yfinite);
                    ys = ys(yfinite);
                    yn = yn(yfinite);
                    
                    
                    y_scatter = [y_scatter ym];
                    x_scatter = [x_scatter ones(size(ym))*i];
                                        
                    [M, S, N] = combine_stats(ym,ys,yn);
                    
                    if grouping == 1 % Pixels                
                        y_mean(i) = M;
                        y_err(i) = S;
                        Ns = N / r.smoothing;
                        
                    else
                        y_mean(i) = mean(ym);
                        y_err(i) = std(ym);
                        N = length(ym);
                        Ns = length(ym);
                    end
                    
                    if error_type == 2
                        y_err(i) = y_err(i) / sqrt(Ns);
                    elseif error_type == 3                        
                        y_err(i) = y_err(i) / sqrt(Ns) * 1.96;
                    end
                    
                    y_n(i) = N;
                    %err(i) = e/yn;

                end

                %if ~all(err==0) && ~all(isnan(err))
                %    y_err = err;
                %end

                if var_is_numeric
                    
                    if display == 1 || display == 2
                        errorbar(ax,x_data,y_mean,y_err,'or-','LineWidth',2,'MarkerSize',6,'MarkerFaceColor','r');

                        if display == 2
                            hold(ax,'on');
                            plot(ax,x_data(x_scatter),y_scatter,'x','MarkerSize',5);
                        end
                        
                        hold(ax,'off');
                    else
                        boxplot(ax,y_scatter,x_scatter,'labels',num2cell(x_data(x_scatter)));
                    end
                    
                    cell_x_data = num2cell(x_data);
                    
                else
                    
                    if display == 1 || display == 2
                        errorbar(ax,y_mean,y_err,'or-','LineWidth',2,'MarkerSize',6,'MarkerFaceColor','r');
                    
                        if display == 2
                            hold(ax,'on');
                            plot(ax,x_scatter,y_scatter,'x','MarkerSize',5);
                        end
                    else
                        boxplot(ax,y_scatter,x_scatter,'labels',x_data);
                    end
                    
                    hold(ax,'on')
                    set(ax,'XTick',1:length(y_mean));
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
                %{
                if isnan(lims(1)) || lims(1) > min(y_mean);
                    lims(1) = 0.9*min(y_mean);
                end
                if isnan(lims(2)) || lims(2) < max(y_mean);
                    lims(2) = 1.1*max(y_mean);
                end
                %}
                if all(isfinite(lims))
                    set(ax,'YLim',lims);
                end
                
                if isnumeric(x_data) && all(~isnan(x_data)) && length(x_data) > 1 && display < 3
                    set(ax,'XLim',[nanmin(x_data) nanmax(x_data)])
                end
                
                obj.raw_data = [cell_x_data; num2cell(y_mean); num2cell(y_err); num2cell(y_n)]';
       
                switch grouping
                    case 1
                        g = 'pixel';
                    case 2 
                        g = 'region';
                    case 3
                        g = 'FOV';
                end
                
                switch error_type
                    case 1
                        e = 'std dev';
                    case 2
                        e = 'std err';
                    case 3
                        e = '95% conf';
                end
                
                obj.raw_data = [{obj.ind_param [r.params{param} ' ' g ' mean'] e 'count'}; obj.raw_data]; 
                
                ylabel(ax,r.latex_params{param});
                xlabel(ax,obj.ind_param);
  
            else
                cla(ax);
            end
            
        end


        
    end
    
    
end

