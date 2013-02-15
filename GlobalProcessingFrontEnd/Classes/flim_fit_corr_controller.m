classdef flim_fit_corr_controller < abstract_plot_controller
    
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
        corr_source_popupmenu;
        corr_display_popupmenu;
        corr_scale_popupmenu;
        corr_independent_popupmenu;
        ind_param;
    end
    
    methods
        function obj = flim_fit_corr_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.corr_axes,[handles.corr_param_x_popupmenu handles.corr_param_y_popupmenu]);
            assign_handles(obj,handles);
            
            set(obj.corr_independent_popupmenu,'Callback',@obj.ind_param_select_update);
            set(obj.corr_source_popupmenu,'Callback',@(~,~)obj.update_display);
            set(obj.corr_display_popupmenu,'Callback',@(~,~)obj.update_display);
            set(obj.corr_scale_popupmenu,'Callback',@(~,~)obj.update_display);
            
            obj.update_display();
        end

        function ind_param_select_update(obj,~,~)
            idx = get(obj.corr_independent_popupmenu,'Value');
            r = obj.fit_controller.fit_result;            
            ind_vars = ['-'; fieldnames(r.metadata)];
            if idx > length(ind_vars) || idx == 0
                idx = 1;
                set(obj.corr_independent_popupmenu,'Value',idx);
            end
            
            obj.ind_param = ind_vars{idx};
            obj.update_display();
        end
        
        function plot_fit_update(obj)
            if obj.fit_controller.has_fit
                
                r = obj.fit_controller.fit_result;            
                ind_vars = fieldnames(r.metadata);
                
                set(obj.corr_independent_popupmenu,'String',['-'; ind_vars]);
                
                obj.ind_param_select_update([],[]);  
            end
        end

        function draw_plot(obj,ax,param)
            
            source = get(obj.corr_source_popupmenu,'Value');
            display = get(obj.corr_display_popupmenu,'Value');
            scale = get(obj.corr_scale_popupmenu,'Value');
                
            if source == 1
                sel = obj.selected;
                indexing = 'dataset';
            else
                sel = obj.fit_controller.selected;
                indexing = 'result';
            end
                                    
            cla(ax)
            if obj.fit_controller.has_fit && all(param > 0)
                
                f = obj.fit_controller;
                r = f.fit_result;
            
                param_data_x = [];
                param_data_y = [];
                md = {};
                for i=1:length(sel)
                    
                    if display == 1 % Pixels
                        new_x = f.get_image(sel(i),param(1),indexing);
                        new_y = f.get_image(sel(i),param(2),indexing);

                        filt = isfinite( new_x ) & isfinite( new_y );

                        new_x = new_x(filt);
                        new_y = new_y(filt);
                    else % Regions
                        new_x = r.region_stats{sel(i)}.mean(param(1),:)';
                        new_y = r.region_stats{sel(i)}.mean(param(2),:)';
                    end
                    
                    param_data_x = [param_data_x; new_x];
                    param_data_y = [param_data_y; new_y];
                    
                    if display == 2 &&  ~strcmp(obj.ind_param,'-')  
                        md = [md r.metadata.(obj.ind_param)(sel(i))];
                    end
                end
                                
                x_lim = f.get_cur_lims(param(1));
                y_lim = f.get_cur_lims(param(2));
                
                sel = param_data_x >= x_lim(1) & param_data_x <= x_lim(2) ...
                    & param_data_y >= y_lim(1) & param_data_y <= y_lim(2);      
                
                param_data_x = param_data_x( sel );
                param_data_y = param_data_y( sel );
                
                if display == 1 % Pixels
                    x_edge = linspace(x_lim(1),x_lim(2),128);
                    y_edge = linspace(y_lim(1),y_lim(2),128);

                    c = histcn([param_data_y param_data_x],y_edge,x_edge);
                    
                    if scale == 2 % display logarithmic
                        c = log(c);
                        c(~isfinite(c)) = nan;
                    end
                        
                    m=256;

                    mn = nanmin(c(:));
                    mx = nanmax(c(:));
                    c = (c - mn)/(mx-mn);
                    c = uint32(c * m);

                    cmap = jet(m);
                    c = ind2rgb(c,cmap);

                    im = image(x_edge,y_edge,c,'Parent',ax);
                    
                    if ( ax == obj.plot_handle )
                        set(im,'uicontextmenu',obj.contextmenu);
                    end
                else % Regions
                    
                    
                    if ~isempty(md)
                        md = md(sel);
                        if (all(cellfun(@isnumeric,md)))
                            md = cell2mat(md);
                            [u,~,ib] = unique(md);
                            u = num2cell(u);
                            u = cellfun(@num2str,u,'UniformOutput',false);
                        else
                            [u,~,ib] = unique(md);
                        end
                    else
                        u = 1;
                        ib = ones(size(param_data_x));
                    end
                    cmap = lines(length(u));

                    h = zeros(length(u),1);
                    for i=1:length(u)
                        h(i) = plot(ax,param_data_x(ib==i),param_data_y(ib==i),'x','Color',cmap(i,:));
                        hold(ax,'on');
                    end
                    if ~isempty(md)
                        legend(ax,h,u)
                    end
                    hold off;
                end
                
                
                
                set(ax,'YDir','normal')
                set(ax,'XLim', x_lim,'YLim', y_lim);
                
                pbaspect(ax,[1 1 1])
                
                xlabel(ax,r.latex_params{param(1)});
                ylabel(ax,r.latex_params{param(2)});
            else
                cla(ax);
            end
        end
        
    end
    
end


