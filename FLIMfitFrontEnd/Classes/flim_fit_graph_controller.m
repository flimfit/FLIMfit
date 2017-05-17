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
        graph_weighting_popupmenu;
        graph_display_popupmenu;
        graph_dcm_popupmenu;
    end
    
    
    
    methods
        function obj = flim_fit_graph_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.graph_axes,handles.graph_dependent_popupmenu,true);            
            assign_handles(obj,handles);

            set(obj.graph_independent_popupmenu,'Callback',@obj.ind_param_select_update);
            
            set(obj.error_type_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_grouping_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_weighting_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_display_popupmenu,'Callback',@(~,~,~) obj.update_display);
            set(obj.graph_dcm_popupmenu,'Callback',@(~,~,~) obj.update_display)
            
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
                set(get(ax,'Parent'),'BackgroundColor','w');
            end
            
            param = obj.cur_param;
            
            
            error_type = get(obj.error_type_popupmenu,'Value');
            grouping = get(obj.graph_grouping_popupmenu,'Value');
            display = get(obj.graph_display_popupmenu,'Value');
            dcm_toggle = get(obj.graph_dcm_popupmenu,'Value')-1;
            weighting = get(obj.graph_weighting_popupmenu,'Value');

            if weighting == 1 % none            
                mean_param = 'mean';
                std_param = 'std';
            else % intensity weighting
                mean_param = 'w_mean';
                std_param = 'w_std';
            end
            
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
                    
                    md = lower(md);
                    x_data = unique(md);
                    x_data = sort_nat(x_data);
                end

                y_scatter = [];
                x_scatter = [];
                f_scatter = [];
                r_scatter = [];
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
                    yf = [];
                    yr = [];
                    
                    idx = 1;
                    for j=x_sel

                        n = r.image_size{j};
                        if n > 0

                            if grouping == 1 || grouping == 3 || grouping == 4
                                ym(idx) = r.image_stats{j}.(mean_param)(param);
                                ys(idx) = r.image_stats{j}.(std_param)(param);
                                yn(idx) = n;
                                if isfield(r.metadata,'FOV')
                                    yf(idx) = cell2mat(r.metadata.FOV(x_sel(idx)));
                                    yr = yf;
                                else
                                    yf(idx) = NaN;
                                    yr(idx) = NaN;
                                end
                            else
                                ym = [ym r.region_stats{j}.(mean_param)(param,:)];
                                ys = [ys r.region_stats{j}.(std_param)(param,:)];
                                yn = [yn r.region_size{j}];
                                if isfield(r.metadata,'FOV')
                                    yf = [yf repmat(r.metadata.FOV(x_sel(idx)),1,length(r.regions{j}))];
                                else
                                    yf = [yf NaN(1,length(r.regions{j}))];
                                end
                                yr = [yr r.regions{j}];
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
                    yf = yf(yfinite);
                    yr = yr(yfinite);
                    
                    %Combine FOVwise stats wellwise, replace ym so that
                    %scatter is displayed according to well.  
                    if grouping == 4
                        if isfield(r.metadata,'Well')
                            wm = [];
                            ws = [];
                            wn = [];

                            widx = 1;
                            for w = unique(r.metadata.Well(x_sel))
                               [wm(widx),ws(widx),wn(widx)] = combine_stats(ym(strcmp(w{1},r.metadata.Well(x_sel))),...
                                   ys(strcmp(w{1},r.metadata.Well(x_sel))),yn(strcmp(w{1},r.metadata.Well(x_sel))));
                               yw(widx) = w;
                               widx = widx+1;
                            end

                            ym = wm; 
                            ys = ws;
                            yn = wn;
                            yf = yw;
                        
                        else
                            %Workaround to block user from selecting combine by
                            %well if none exist...
                            %Alternative: disable/grey out this option, but
                            %problem of where to check.  
                            grouping = 3;                
                            set(obj.graph_grouping_popupmenu,'Value',grouping);   
                        end
                    end
                    
                    y_scatter = [y_scatter ym];
                    x_scatter = [x_scatter ones(size(ym))*i];
                    f_scatter = [f_scatter yf];
                    r_scatter = [r_scatter yr];
                                        
                    [M, S, N] = combine_stats(ym,ys,yn);
                    
                    if grouping == 1 % Pixels                
                        y_mean(i) = M;
                        y_std(i) = S;
                        Ns = N / r.smoothing;
                        
                    else
                        y_mean(i) = mean(ym);
                        y_std(i) = std(ym);
                        N = length(ym);
                        Ns = length(ym);
                    end
                    
                    y_err(i) = y_std(i) / sqrt(Ns);
                    y_conf(i) = y_std(i) / sqrt(Ns) * 1.96;                    
                    y_n(i) = N;

                end
                
                switch error_type
                    case 1
                        y_err_disp = y_std;
                    case 2
                        y_err_disp = y_err;
                    case 3
                        y_err_disp = y_conf;
                end
                
                hs = 0;
                if var_is_numeric
                    
                    if display == 1 || display == 2
                        he = errorbar(ax,x_data,y_mean,y_err_disp,'ok-','LineWidth',1,'MarkerSize',6,'MarkerFaceColor','k');

                        if display == 2
                            hold(ax,'on');
                            hs = plotSpread(ax,y_scatter,'distributionIdx',x_scatter,'distributionColors',[0.5 0.5 0.5],'xValues',x_data);
                            %hs = plot(ax,x_data(x_scatter),y_scatter,'x','MarkerSize',5);
                        end
                        
                        hold(ax,'off');
                    else
                        boxplot(ax,y_scatter,x_scatter,'labels',num2cell(x_data(x_scatter)));
                    end
                    
                    xlim(ax,[min(x_data) - 0.5, max(x_data) + 0.5])

                    
                    cell_x_data = num2cell(x_data);
                    
                else
                    
                    if display <= 2
                        he = errorbar(ax,y_mean,y_err_disp,'ok','LineWidth',1,'MarkerSize',6,'MarkerFaceColor','k');
                    
                        if display == 2
                            hold(ax,'on');
                            hs = plotSpread(ax,y_scatter,'distributionIdx',x_scatter,'distributionColors',[0.5 0.5 0.5],'spreadWidth',0.8);

%                            hs = plot(ax,x_scatter,y_scatter,'x','MarkerSize',5);
                        end
                    else
                        boxplot(ax,y_scatter,x_scatter,'labels',x_data);
                    end
                    
                    hold(ax,'on')
                    set(ax,'XTick',1:length(y_mean));
                    set(ax,'XTickLabel',x_data);                    
                    cell_x_data = x_data;
                    
                    xlim(ax,[0.5, length(y_mean) + 0.5])

                end

                fig = obj.window;
                dcm_obj = datacursormode(fig);
                dcm_style = {'datatip' 'window'};
                if (display == 1 || display == 2) && dcm_toggle
%                 if (display == 1 || display == 2)
                    set(dcm_obj,'Enable','on','DisplayStyle',dcm_style{dcm_toggle});
%                     set(dcm_obj,'Enable','on','DisplayStyle',dcm_style{1});
                    set(dcm_obj,'UpdateFcn',{@interactive_plot_update,obj,y_scatter,f_scatter,r_scatter,grouping,x_data,hs});
%                     set(get(get(dcm_obj,'UIContextMenu'),'Children'),'Visible','on')
                    set(obj.plot_handle,'uicontextmenu',obj.contextmenu);
                else
                    set(dcm_obj,'Enable','off');
                end
                
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
                
                obj.raw_data = [cell_x_data; num2cell(y_mean); num2cell(y_std); num2cell(y_err); num2cell(y_conf); num2cell(y_n)]';
       
                switch grouping
                    case 1
                        g = 'pixel';
                    case 2 
                        g = 'region';
                    case 3
                        g = 'FOV';
                    case 4
                        g = 'well';
                end
               
                
                obj.raw_data = [{obj.ind_param [r.params{param} ' ' g ' mean'] 'std dev' 'std err' '95% conf' 'count'}; obj.raw_data]; 
                
                ylabel(ax,r.latex_params{param});
                xlabel(ax,obj.ind_param);
                set(ax,'Box','off','TickDir','out')
  
%                 chandles = allchild(ax);
%                 set(chandles,'uicontextmenu',obj.contextmenu);
%                 set(obj.plot_handle,'uicontextmenu',obj.contextmenu)
%                 set(allchild(obj.plot_handle),'uicontextmenu',obj.contextmenu);
               
                
            else
                cla(ax);
            end
            
        end

    
    
        
    end
    
    
    
end
