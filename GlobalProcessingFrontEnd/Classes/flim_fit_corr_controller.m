classdef flim_fit_corr_controller < abstract_plot_controller
    
    properties
        corr_source_popupmenu;
        corr_display_popupmenu;
    end
    
    methods
        function obj = flim_fit_corr_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.corr_axes,[handles.corr_param_x_popupmenu handles.corr_param_y_popupmenu]);
            assign_handles(obj,handles);
            
            set(obj.corr_source_popupmenu,'Callback',@(~,~)obj.update_display);
            set(obj.corr_display_popupmenu,'Callback',@(~,~)obj.update_display);
            
            obj.update_display();
        end

        function plot_fit_update(obj)
        end

        function draw_plot(obj,ax,param)
            
            source = get(obj.corr_source_popupmenu,'Value');
            display = get(obj.corr_display_popupmenu,'Value');
                
            if source == 1
                sel = obj.data_series_list.selected;
            else
                sel = obj.fit_controller.selected;
            end
                                    
            cla(ax)
            if obj.fit_controller.has_fit && all(param > 0)
                
                f = obj.fit_controller;
                r = f.fit_result;
            
                param_data_x = [];
                param_data_y = [];
                for i=1:length(sel)
                    
                    if display == 1 % Pixels
                        new_x = f.get_image(sel(i),param(1));
                        new_y = f.get_image(sel(i),param(2));

                        filt = isfinite( new_x ) & isfinite( new_y );

                        new_x = new_x(filt);
                        new_y = new_y(filt);
                    else % Regions
                        new_x = r.region_mean{sel(i)}(param(1),:)';
                        new_y = r.region_mean{sel(i)}(param(2),:)';
                    end
                    
                    param_data_x = [param_data_x; new_x];
                    param_data_y = [param_data_y; new_y];
                    
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

                    m=256;

                    mn = min(c(:));
                    mx = max(c(:));
                    c = (c - mn)/(mx-mn);
                    c = uint32(c * m);

                    cmap = jet(m);
                    c = ind2rgb(c,cmap);

                    im = image(x_edge,y_edge,c,'Parent',ax);
                    
                    if ( ax == obj.plot_handle )
                        set(im,'uicontextmenu',obj.contextmenu);
                    end
                else % Regions
                    plot(ax,param_data_x,param_data_y,'x');
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


