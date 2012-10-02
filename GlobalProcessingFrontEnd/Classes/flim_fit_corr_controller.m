classdef flim_fit_corr_controller < abstract_plot_controller
    
    methods
        function obj = flim_fit_corr_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.corr_axes,[handles.corr_param_x_popupmenu handles.corr_param_y_popupmenu]);
            assign_handles(obj,handles);
            
            obj.update_display();
        end

        function plot_fit_update(obj)
        end

        function draw_plot(obj,ax,param)
            
            sel = obj.data_series_list.selected;
            
            %sel = obj.fit_controller.selected;
            
            cla(ax)
            if obj.fit_controller.has_fit && all(param > 0)
                
                r = obj.fit_controller.fit_result;
                
                param_data_x = [];
                param_data_y = [];
                for i=1:length(sel)
                    new_x = obj.fit_controller.get_image(sel(i),param{1});
                    new_y = obj.fit_controller.get_image(sel(i),param{2});
                    
                    filt = isfinite( new_x ) & isfinite( new_y );
                     
                    new_x = new_x(filt);
                    new_y = new_y(filt);
                    
                    param_data_x = [param_data_x; new_x];
                    param_data_y = [param_data_y; new_y];
                    
                end
                x_lim = r.get_cur_lims(param(1));
                y_lim = r.get_cur_lims(param(2));
                
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
                
                pbaspect(ax,[1 1 1])
                
                xlabel(ax,param{1});
                ylabel(ax,param{2});
            else
                cla(ax);
            end
        end
        
    end
    
end


