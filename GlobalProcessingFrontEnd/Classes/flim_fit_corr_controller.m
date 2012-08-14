classdef flim_fit_corr_controller < abstract_plot_controller
   
    properties
        param_x;
        param_y;
    end
    
    methods
        function obj = flim_fit_corr_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.corr_axes,[handles.corr_param_x_popupmenu handles.corr_param_y_popupmenu]);
            assign_handles(obj,handles);
            
            obj.update_display();
        end

        function plot_fit_update(obj)
        end

        function draw_plot(obj,ax,param)
            
            selected = obj.data_series_list.selected;
            
            cla(ax)
            if obj.fit_controller.has_fit && ~isempty(param{1}) && ~isempty(param{2})
                
                r = obj.fit_controller.fit_result;
                
                param_data_x = r.get_image(selected,param{1});
                param_data_y = r.get_image(selected,param{2});

                x_lim = r.default_lims.(param{1});
                y_lim = r.default_lims.(param{2});
                
                sel = param_data_x >= x_lim(1) & param_data_x <= x_lim(2) ...
                    & param_data_y >= y_lim(1) & param_data_y <= y_lim(2);      
                
                param_data_x = param_data_x( sel );
                param_data_y = param_data_y( sel );
                
                
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
                
                set(ax,'YDir','normal')
                set(ax,'XLim', x_lim,'YLim', y_lim);
                
                xlabel(ax,param{1});
                ylabel(ax,param{2});
            else
                cla(ax);
            end
        end
        
    end
    
end


