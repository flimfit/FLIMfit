classdef flim_fit_gallery_controller < abstract_plot_controller
    
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
        gallery_cols_edit;
        gallery_overlay_popupmenu;
        gallery_unit_edit; 
        gallery_merge_popupmenu;
        gallery_slider;
        
        axes_handles;
        colorbar_handles;
    end
    
    methods
        function obj = flim_fit_gallery_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.gallery_panel,handles.gallery_param_popupmenu,false);            
            assign_handles(obj,handles);
            
           
            set(obj.plot_handle,'ResizeFcn',@(~,~,~) obj.update_display);

            set(obj.plot_handle,'Units','Pixels');
             
            set(obj.gallery_cols_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_overlay_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_unit_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_merge_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_slider,'Callback',@obj.gallery_params_update);
            
            obj.register_tab_function('Gallery');
            obj.update_display();
        end
        
        function gallery_params_update(obj,~,~)
            cols = round(str2double(get(obj.gallery_cols_edit,'String')));
            set(obj.gallery_cols_edit,'String',num2str(cols));
            
            obj.update_display();
        end
        
        function plot_fit_update(obj)
            if obj.fit_controller.has_fit
                r = obj.fit_controller.fit_result;
                metafields = fieldnames(r.metadata);
                set(obj.gallery_overlay_popupmenu,'String',['-' metafields']);
            end
        end
        
        function draw_plot(obj,fig)
           
            export_plot = (nargin == 2);
            if ~export_plot
                fig = obj.plot_handle;
            end

            
            param = obj.cur_param;
            
            f = obj.fit_controller;
            r = f.fit_result;
            sel = obj.fit_controller.selected;
           
            children = get(fig,'Children');
            delete(children);
            
            if ~obj.fit_controller.has_fit || param == 0 
                return
            end
            
            merge = get(obj.gallery_merge_popupmenu,'Value');
            merge = merge - 1;
            
            overlay = get(obj.gallery_overlay_popupmenu,'Value');
            names = get(obj.gallery_overlay_popupmenu,'String');
            if overlay == 1 || overlay > length(names)
                overlay = [];
            else
                overlay = names{overlay};
            end

            unit = get(obj.gallery_unit_edit,'String');
            cols = str2double(get(obj.gallery_cols_edit,'String'));
            
            
            if export_plot
                pa = fig;%get(f,'Parent');
                pos_fig = get(pa,'Position');
                pos = get(obj.plot_handle,'Position');
                pos_fig(3:4) = pos(3:4);
                set(pa,'Position',pos_fig);
            end
            
            
                       
            
            %{
            % Find first cols entry from each Column and sort by column order
            % ---
            sort_param = cell2mat(r.metadata.Column(sel));
            entries = unique(sort_param);
            new_sel = [];
            for i=1:length(entries)
                cols_eq = sort_param == entries(i);
                idx = find(cols_eq,cols,'first');
                new_sel = [new_sel sel(idx)];
            end

            sort_param = cell2mat(r.metadata.Column(new_sel));
            [~,idx] = sort(sort_param);
            sel = new_sel(idx);
            % --- 
            %}
            


            n_im = length(sel);
            
            total_rows = ceil(n_im/cols);

            if n_im > 0
                
                
                if isempty(overlay);
                    meta = [];
                else
                    meta = r.metadata.(overlay);
                end
                
                cbar_size = 20;
                
                pos = get(fig,'Position');
                fig_size = pos(3:4);
                fig_size(1) = fig_size(1) - cbar_size;
                
                new_width = floor(fig_size(1)/cols);
                ratio = new_width/r.width;
                new_height = floor(r.height*ratio);
                
                max_rows = floor(fig_size(2)/new_height);
                max_rows = max(max_rows,1);
                
                rows = min(max_rows,total_rows);
                
                n_disp = cols * rows;
                
                gw = r.width * cols; gh = r.height * rows;
                gallery_data = NaN([gh gw]);
                gallery_I_data = NaN([gh gw]);
                
                if export_plot
                    fh = pos(3)*gh/gw;
                    pos(4) = fh;
                    fig_size(2) = fh;
                    set(fig,'Position',pos)
                end
                
                scroll_pos = max(total_rows - max_rows,0);
                
                warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid')
                pos = get(obj.gallery_slider,'Position');
                h = new_height*rows;
                pos = [pos(1) fig_size(2)-h pos(3) h];
                
                if scroll_pos > 0
                    step = [1 rows]/scroll_pos;
                else
                    step = [1 1];
                end
                set(obj.gallery_slider,'Min',0,'Max',scroll_pos,'SliderStep',step,'Position',pos);
                val = get(obj.gallery_slider,'Value');
                val = round(val);
                val = min(val,scroll_pos);
                val = max(0,val);
                set(obj.gallery_slider,'Value',val);
                
                
                start_row = scroll_pos-val;
                
                start = start_row*cols+1;
                finish = min(n_im,start+n_disp-1);
                                
                
                idx = 0;
                label = cell(1,finish-start+1);
                                
                for i=start:finish
                    
                    ri = mod(idx,cols) * r.width + 1;
                    ci = floor(idx/cols) * r.height + 1;
                    idx = idx + 1;
                    
                    im_data = obj.fit_controller.get_image(sel(i),param,'result');
                    
                    %{
                    im_data1 = obj.fit_controller.get_image(sel(i),'offset','result');
                    im_data2 = obj.fit_controller.get_image(sel(i),'I0','result');
                    
                    im_data = im_data2 ./ im_data1;
                    %im_data = im_data2;
                    %}
                    
                    %mdata = obj.apply_colourmap(im_data,param,f.get_cur_lims(param));
                    
                    %M(i) = im2frame(mdata);
                    
                    if merge
                        I_data = f.get_intensity(sel(i),'result');
                        gallery_I_data(ci:ci+r.height-1,ri:ri+r.width-1) = I_data;
                    
                    end
                    gallery_data(ci:ci+r.height-1,ri:ri+r.width-1) = im_data;
                    

                    if ~isempty(meta)
                        t = meta{sel(i)};
                        if strcmp(overlay,'s') && strcmp(unit,'min')
                            t = t / 60;
                        end
                        if ~ischar(t)
                            t = num2str(t);
                        end
                        t = [t ' ' unit];
                    else
                        t = '';
                    end
                    label{idx} = t;
                end
                
                %implay(M);
                
                % Subsample if possible
                scale = max(floor(1/ratio),1);
                gallery_data = gallery_data(1:scale:end,1:scale:end);
                gallery_I_data = gallery_I_data(1:scale:end,1:scale:end);
                
                ax = axes('Parent',fig);
                cbar = axes('Parent',fig);
                
                cscale = obj.colourscale(param);
                lims = f.get_cur_lims(param);
                I_lims = f.get_cur_intensity_lims;
                
                if ~merge
                    im=colorbar_flush(ax,cbar,gallery_data,isnan(gallery_data),lims,cscale,[]);
                else
                    im=colorbar_flush(ax,cbar,gallery_data,isnan(gallery_data),lims,cscale,[],gallery_I_data,I_lims);
                end
                   
                w = new_width*cols;
                h = new_height*rows;
                
                y = fig_size(2)-h - 1;
                set(ax,'XTick',[],'YTick',[],'Units','pixels','Position',[1 y w h ]);
                set(cbar,'XTick',[],'YTick',[],'Units','pixels','Position',[w y cbar_size h]);
                
                if ( fig == obj.plot_handle )
                    set(im,'uicontextmenu',obj.contextmenu);
                end

                
                idx = 1;
                for i=1:rows
                   for j=1:cols
                       if idx <= length(label)
                           y = (i-1)*r.height/scale+2;
                           x = (j-1)*r.width/scale+2;
                           text(x, y, label{idx},'Parent',ax,...
                             'Color','w','BackgroundColor','k','Margin',1,...
                             'FontUnits','points','FontSize',10,...
                             'HorizontalAlignment','left','VerticalAlignment','top');
                           idx = idx + 1;
                       end
                   end
                end
                
                for i=1:cols-1
                     line([r.width+0.5 r.width+0.5]*i/scale,[0 r.height*rows+0.5]/scale,'Parent',ax,'Color','w');
                end
                for i=1:rows-1
                     line([0 r.width*cols+0.5]/scale,[r.height+0.5 r.height+0.5]*i/scale,'Parent',ax,'Color','w');
                end
                
            end
            
        end
        
    end
end