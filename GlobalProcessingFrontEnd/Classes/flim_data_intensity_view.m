classdef flim_data_intensity_view < handle & flim_data_series_observer
   
    properties
       intensity_axes;
       data_series_list;
       im;
       colorbar_axes;
       callback = [];
    end
 
    methods
                
        function obj = flim_data_intensity_view(handles)
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
            parent = get(obj.intensity_axes,'Parent');
            addlistener(parent,'Position','PostSet',@obj.update_figure);
            obj.update_figure();
        end
        
        function data_set(obj)
            addlistener(obj.data_series,'masking_updated',@obj.data_update_evt);
            if ~isempty(obj.data_series_list)
                addlistener(obj.data_series_list,'selection_updated',@obj.data_update_evt);
            end
        end
        
        function set_click_callback(obj,callback)
            obj.callback = callback;
            set(obj.intensity_axes,'ButtonDownFcn',callback)
        end

        function data_update(obj)
            obj.update_figure();
        end
        
        function update_figure(obj,~,~)
            
            ax = obj.intensity_axes;
            
            if (obj.data_series.init)
                            
                selected = obj.data_series_list.selected;
                intensity = obj.data_series.selected_intensity(selected);
              
                try
                    lim(1) = nanmin(intensity(intensity>0))-1;
                catch
                    lim(1) = 0;
                end
                
                lim(2) = nanmax(intensity(:))+1;
                
                intensity = (intensity - lim(1))/(lim(2)-lim(1));
                mask = intensity < 0 | intensity > 1;
                intensity = uint32(intensity * 2^16);
                intensity = intensity + 1;
                intensity(mask) = 0;

                cmap = gray(2^16-1);
                cmap = [ [1,0,0]; cmap];

                mapped_data = ind2rgb(intensity,cmap);

                if ~isempty(obj.im) && all(size(get(obj.im,'CData'))==size(mapped_data))
                    set(obj.im,'CData',mapped_data);
                else
                    obj.im = image(mapped_data,'Parent',ax);
                end
                
                set(ax, 'units', 'pixels','XTick',[],'YTick',[]);
                daspect(ax,[1 1 1]);

                pos=plotboxpos(ax);

                bar_pos = [pos(1)+pos(3) pos(2) 7 pos(4)];

                
                cmap = gray(256);
                a = (256:-1:1)';
                a = ind2rgb(a,cmap);
                
                
                
                parent = get(ax,'Parent');
                if isempty(obj.colorbar_axes)
                	obj.colorbar_axes(1) = axes('Units','pixels','Position',bar_pos,'YTick',[],'XTick',[],'Box','on','Parent',parent);
                    image(a,'Parent',obj.colorbar_axes(1));
                else
                    set(obj.colorbar_axes(1),'Units','pixels','Position',bar_pos);
                end
                
                
                set(obj.colorbar_axes(1),'XTick',[],'YTick',[]);
                
                if length(obj.colorbar_axes)==3
                    if ishandle(obj.colorbar_axes(2))
                        delete(obj.colorbar_axes(2));
                    end
                    if ishandle(obj.colorbar_axes(3))
                        delete(obj.colorbar_axes(3));
                    end

                end
                    
                obj.colorbar_axes(2) = text(pos(3), 2, num2str(lim(1)),'Units','pixels','Parent',ax,...
                     'Color','w','BackgroundColor','k','Margin',1,...
                     'HorizontalAlignment','right','VerticalAlignment','bottom');

                obj.colorbar_axes(3) = text(pos(3), pos(4), num2str(lim(2)),'Units','pixels','Parent',ax,...
                     'Color','w','BackgroundColor','k','Margin',1,...
                     'HorizontalAlignment','right','VerticalAlignment','top');
    
                colormap(ax,'gray');
               
                set(obj.im, 'HitTest', 'off');
                set(obj.intensity_axes,'ButtonDownFcn',obj.callback);
                
                set(ax, 'units', 'normalized');
                set(obj.colorbar_axes, 'units', 'normalized');
               

            end
            
            set(ax,'Box','on');
            set(ax,'XTick',[]);
            set(ax,'YTick',[]);
            
        end

    end
    
end