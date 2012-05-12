classdef flim_fit_gallery_controller < abstract_plot_controller

    properties
        gallery_cols_edit;
        gallery_overlay_popupmenu;
        gallery_unit_edit; 
        gallery_merge_popupmenu;
        
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

            set(obj.gallery_cols_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_overlay_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_unit_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_merge_popupmenu,'Callback',@obj.gallery_params_update);
            
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
            
            r = obj.fit_controller.fit_result;
            
            if save
                pa = f;%get(f,'Parent');
                pos = get(pa,'Position');
                pos = [0,0,800,600];
                set(pa,'Position',pos);
            end
            
            if ~obj.fit_controller.has_fit || isempty(param) 
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

            d = obj.fit_controller.data_series;
            n_im = d.n_datasets;
            
            rows = ceil(n_im/cols);

            if ~strcmp(param,'-')
                
                if save || (n_im>0 && (cols ~= obj.cols || rows ~= obj.rows))
                    [ax_h,cb_h] = tight_subplot(f,n_im,rows,cols,false,[d.width d.height],5,5);
                    obj.cols = cols;
                    obj.rows = rows;
                else
                    ax_h = obj.axes_handles;
                    cb_h = obj.colorbar_handles;
                end

                if isempty(overlay);
                    meta = [];
                else
                    meta = d.metadata.(overlay);
                end
                
                %{
                gw = d.width * cols; gh = d.height * rows;
                gallery_data = zeros([gh gw]);
                %}
                
                for i=1:n_im
                    %{
                    im_data = r.get_image(i,param);
                    
                    ri = mod(i-1,cols) * d.width + 1;
                    ci = floor((i-1)/cols) * d.height + 1;
                    
                    gallery_data(ci:ci+d.height-1,ri:ri+d.width-1) = im_data;
                    %}
                    
                    
                    if ~isempty(meta)
                        text = meta{i};
                        if strcmp(overlay,'s') && strcmp(unit,'min')
                            text = text / 60;
                        end
                        if ~ischar(text)
                            text = num2str(text);
                        end
                        text = [text ' ' unit];
                    else
                        text = '';
                    end

                    obj.plot_figure(ax_h(i),cb_h(i),i,param,merge,text);
                    
                    if ~save
                        obj.axes_handles = ax_h;
                        obj.colorbar_handles = cb_h;
                    end
                    
                end
                
                %{
                gallery_data = imresize(gallery_data,1/4);
                ax = axes('Parent',f);
                im=imagesc(gallery_data,'Parent',ax);    
                daspect(ax,[1 1 1])
                %}
                

            end
            
        end
        
    end
end