classdef flim_fit_gallery_controller < abstract_plot_controller

    properties
        gallery_cols_edit;
        gallery_overlay_popupmenu;
        gallery_unit_edit; 
        gallery_merge_popupmenu;
        gallery_slider;
        
        axes_handles;
        colorbar_handles;
        cols = 0;
        rows = 0;
    end
    
    methods
        function obj = flim_fit_gallery_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.gallery_panel,handles.gallery_param_popupmenu);            
            assign_handles(obj,handles);
            
           
            addlistener(obj.plot_handle,'Position','PostSet',@(~,~,~) obj.update_display);

            set(obj.plot_handle,'Units','Pixels');
             
            set(obj.gallery_cols_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_overlay_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_unit_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_merge_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_slider,'Callback',@obj.gallery_params_update);
            
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
        
        function draw_plot(obj,f,param)
            %return
            save = (f ~= obj.plot_handle);
            
            d = obj.fit_controller.data_series;
            r = obj.fit_controller.fit_result;
            sel = obj.fit_controller.selected;
            
            %{
            sort_param = cell2mat(r.metadata.Column);
            sort_param = sort_param(sel);
            [~,idx] = sort(sort_param);
            sel = sel(idx);
            %}
            
            if save
                pa = f;%get(f,'Parent');
                pos = get(pa,'Position');
                pos = [0,0,800,600];
                set(pa,'Position',pos);
            end
            
            children = get(f,'Children');
            delete(children);
            
            if ~obj.fit_controller.has_fit || param == 0 
                return
            end
            
            merge = get(obj.gallery_merge_popupmenu,'Value');
            merge = merge - 1;
            
            overlay = get(obj.gallery_overlay_popupmenu,'Value');
            if overlay == 1
                overlay = [];
            else
                names = get(obj.gallery_overlay_popupmenu,'String');
                overlay = names{overlay};
            end

            unit = get(obj.gallery_unit_edit,'String');
            cols = str2double(get(obj.gallery_cols_edit,'String'));

            n_im = length(sel);
            
            total_rows = ceil(n_im/cols);

            if ~strcmp(param,'-') && n_im > 0
                
                %{
                if save || (n_im>0 && (cols ~= obj.cols || rows ~= obj.rows))
                    [ax_h,cb_h] = tight_subplot(f,n_im,rows,cols,false,[d.width d.height],5,5);
                    obj.cols = cols;
                    obj.rows = rows;
                else
                    ax_h = obj.axes_handles;
                    cb_h = obj.colorbar_handles;
                end
                %}
                
                if isempty(overlay);
                    meta = [];
                else
                    meta = r.metadata.(overlay);
                end
                
                cbar_size = 20;
                
                pos = get(f,'Position');
                fig_size = pos(3:4);
                fig_size(1) = fig_size(1) - cbar_size;
                
                new_width = floor(fig_size(1)/cols);
                ratio = new_width/d.width;
                new_height = floor(d.height*ratio);
                
                max_rows = floor(fig_size(2)/new_height);
                max_rows = max(max_rows,1);
                
                rows = min(max_rows,total_rows);
                
                n_disp = cols * rows;
                
                gw = d.width * cols; gh = d.height * rows;
                gallery_data = NaN([gh gw]);
                gallery_I_data = NaN([gh gw]);
                
                if save
                    fh = pos(3)*gh/gw;
                    pos(4) = fh;
                    fig_size(2) = fh;
                    set(f,'Position',pos)
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
                    
                    ri = mod(idx,cols) * d.width + 1;
                    ci = floor(idx/cols) * d.height + 1;
                    idx = idx + 1;
                    
                    im_data = obj.fit_controller.get_image(sel(i),param);
                    if merge
                        I_data = r.get_image(sel(i),'I');
                        gallery_I_data(ci:ci+d.height-1,ri:ri+d.width-1) = I_data;
                    
                    end
                    gallery_data(ci:ci+d.height-1,ri:ri+d.width-1) = im_data;
                    
                    
                    
                    
                    
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
                    %{
                    obj.plot_figure(ax_h(i),cb_h(i),i,param,merge,text);
                    
                    if ~save
                        obj.axes_handles = ax_h;
                        obj.colorbar_handles = cb_h;
                    end
                    %}
                end
                
                % Subsample if possible
                scale = max(floor(1/ratio),1);
                gallery_data = gallery_data(1:scale:end,1:scale:end);
                gallery_I_data = gallery_I_data(1:scale:end,1:scale:end);
                
                ax = axes('Parent',f);
                cbar = axes('Parent',f);
                
                cscale = obj.colourscale(param);
                
                if ~merge
                    im=colorbar_flush(ax,cbar,gallery_data,isnan(gallery_data),r.default_lims{param},cscale,[]);
                else
                    im=colorbar_flush(ax,cbar,gallery_data,isnan(gallery_data),r.default_lims{param},cscale,[],gallery_I_data,r.default_lims.I);
                end
                
                %im=imagesc(gallery_data,'Parent',ax);    
                w = new_width*cols;
                h = new_height*rows;
                y = fig_size(2)-h - 1;
                set(ax,'XTick',[],'YTick',[],'Units','pixels','Position',[1 y w h ]);
                %daspect(ax,[1 1 1])
                %set(ax,'Units','pixels');
                %pos=plotboxpos(ax);
                set(cbar,'XTick',[],'YTick',[],'Units','pixels','Position',[w y cbar_size h]);
                
                if ( f == obj.plot_handle )
                    set(im,'uicontextmenu',obj.contextmenu);
                end

                
                idx = 1;
                for i=1:rows
                   for j=1:cols
                       if idx <= length(label)
                           y = (i-1)*d.height/scale+2;
                           x = (j-1)*d.width/scale+2;
                           text(x, y, label{idx},'Parent',ax,...
                             'Color','w','BackgroundColor','k','Margin',1,...
                             'FontUnits','points','FontSize',10,...
                             'HorizontalAlignment','left','VerticalAlignment','top');
                           idx = idx + 1;
                       end
                   end
                end
                
                for i=1:cols-1
                     line([d.width d.width]*i/scale,[0 d.height*rows]/scale,'Parent',ax,'Color','w');
                end
                for i=1:rows-1
                     line([0 d.width*cols]/scale,[d.height d.height]*i/scale,'Parent',ax,'Color','w');
                end
                
            end
            
        end
        
    end
end