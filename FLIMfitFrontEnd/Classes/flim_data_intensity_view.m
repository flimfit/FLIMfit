classdef flim_data_intensity_view < handle & flim_data_series_observer
    
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
       intensity_axes;
       intensity_mode_popupmenu;
       data_series_list;
       im;
       colorbar_axes;
       callback = [];
       lh;
    end
 
    methods
                
        function obj = flim_data_intensity_view(handles)
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
            
            parent = get(obj.intensity_axes,'Parent');
            addlistener(parent,'Position','PostSet',@obj.update_figure);
            
            set(obj.intensity_mode_popupmenu,'Callback',@obj.update_figure);
            if ~isempty(obj.data_series_list)
                addlistener(obj.data_series_list,'selection_updated',@obj.data_update_evt);
            end
            obj.update_figure();
        end
        
        function data_set(obj)
            obj.lh = addlistener(obj.data_series,'masking_updated',@obj.data_update_evt);
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
            
            view = get(obj.intensity_mode_popupmenu,'Value');
            
            m = 2^8;
            
            if (obj.data_series.init)
                
                if ~isempty(obj.data_series_list)       
                    selected = obj.data_series_list.selected;
                else
                    selected = 1;
                end
                
                switch view
                case 1 % integrated intensity
                    intensity = obj.data_series.selected_intensity(selected);
                    flt = intensity(intensity>0 & isfinite(intensity));
                    
                    if isempty(flt)
                        lim(1) = 0;
                        lim(2) = 0;
                    else
                        lim(1) = min(flt);
                        lim(2) = round(prctile(flt,99.5));
                    end
                    
                    cmap = gray(m-1);
                case 2 % background
                    intensity = obj.data_series.background_image;
                    
                    flt = intensity(isfinite(intensity));
                    lim = prctile(flt,[0.01 99.9]);
                    
                    cmap = gray(m-1);
                case 3 % TVB I background
                    intensity = obj.data_series.tvb_I_image;
                    
                    flt = intensity(isfinite(intensity));
                    lim = prctile(flt,[0.01 99.9]);
                    
                    cmap = gray(m-1);
                case 4 % irf image
                    intensity = [];
                    lim = [0 0];
                    
                    cmap = gray(m-1);
                case 5 % t0 map
                    intensity = obj.data_series.t0_image;
                    
                    flt = intensity(isfinite(intensity));
                    lim = prctile(flt,[0.01 99.9]);

                    cmap = jet(m-1);
                end
                
                

               

                intensity = (intensity - lim(1))/(lim(2)-lim(1));
                mask = intensity < 0;
                intensity(intensity > 1) = 1;
                intensity = uint32(intensity * m);
                intensity = intensity + 1;
                intensity(mask) = 0;

               
                cmap = [ [1,0,0]; cmap];

                mapped_data = ind2rgb(intensity,cmap);

                if ~isempty(obj.im) && all(size(get(obj.im,'CData'))==size(mapped_data))
                    set(obj.im,'CData',mapped_data);
                else
                    obj.im = image(mapped_data,'Parent',ax);
                    set(obj.im, 'HitTest', 'off');
                    set(obj.intensity_axes,'ButtonDownFcn',obj.callback);
                end
                
                set(ax, 'units', 'pixels','XTick',[],'YTick',[]);
                daspect(ax,[1 1 1]);

                pos=plotboxpos(ax);

                bar_pos = [pos(1)+pos(3) pos(2) 7 pos(4)];

                a = linspace(m,2,m-1)';
                a = ind2rgb(a,cmap);
                
                parent = get(ax,'Parent');
                if isempty(obj.colorbar_axes)
                	obj.colorbar_axes(1) = axes('Units','pixels','Position',bar_pos,'YTick',[],'XTick',[],'Box','on','Parent',parent);
                else
                    set(obj.colorbar_axes(1),'Units','pixels','Position',bar_pos);
                end
                image(a,'Parent',obj.colorbar_axes(1));
                
                
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
               
                
                
                set(ax, 'units', 'normalized');
                set(obj.colorbar_axes, 'units', 'normalized');
               

            end
            
            set(ax,'Box','on');
            set(ax,'XTick',[]);
            set(ax,'YTick',[]);
            
        end

    end
    
end