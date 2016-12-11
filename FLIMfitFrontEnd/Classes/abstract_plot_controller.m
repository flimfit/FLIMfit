classdef abstract_plot_controller < flim_fit_observer & abstract_display_controller
    
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
        param_popupmenu;
        
        param_list;     
        cur_param;   
        ap_lh;
    end
        
    methods

        
        function obj = abstract_plot_controller(handles,plot_handle,param_popupmenu,exports_data)
                       
            obj = obj@abstract_display_controller(handles,plot_handle,exports_data);
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            obj.plot_handle = plot_handle;
                        
            if nargin >= 3
                obj.param_popupmenu = param_popupmenu;
                set(obj.param_popupmenu,'Callback',@obj.param_select_update);
            else
                obj.param_popupmenu = [];
            end
                                                
            assign_handles(obj,handles);
           
        end
        
        function plot_fit_update(obj) 
        end
        
        function selection_updated(obj,~,~)
            obj.selected = obj.data_series_list.selected;
            obj.update_display();
        end
        
        
        function update_param_menu(obj,~,~)
            if obj.fit_controller.has_fit
                obj.param_list = obj.fit_controller.fit_result.fit_param_list();
                new_list = ['-',obj.param_list];
                for i=1:length(obj.param_popupmenu) 
                    old_list = get(obj.param_popupmenu(i),'String')';
                    
                    changed = length(old_list)~=length(new_list) || ...
                        any(~cellfun(@strcmp,old_list,new_list));

                    if changed
                        set(obj.param_popupmenu(i),'String',new_list);

                        if get(obj.param_popupmenu(i),'Value') > length(obj.param_list)
                            set(obj.param_popupmenu(i),'Value',1);
                        end

                        obj.param_select_update();    
                    end          
                end
            end
            
        end
        
        function param_select_update(obj,src,evt)
            % Get parameters from potentially multiple popupmenus
            val = get(obj.param_popupmenu,'Value');
            if iscell(val)
                val = cell2mat(val);
            end
            idx = val-1;
            obj.cur_param = idx;
            
            obj.update_display();
        end
        
        function lims_update(obj)
            obj.update_display();
        end
        
        function fit_update(obj)
            obj.update_param_menu();
            obj.plot_fit_update();
            obj.update_display();
            obj.ap_lh = addlistener(obj.fit_controller.fit_result,'cur_lims','PostSet',@(~,~) escaped_callback(@obj.lims_update));
        end
        
        function fit_display_update(obj)
            obj.update_display();
        end
                
        function mapped_data = apply_colourmap(obj,data,param,lims)
            
            cscale = obj.colourscale(param);
            
            m=2^8;
            data = data - lims(1);
            data = data / (lims(2) - lims(1));
            data(data > 1) = 1;
            data(data < 0) = 0;
            data = data * m + 1;
            data(isnan(data)) = 0;
            data = int32(data);
            cmap = cscale(m);
            cmap = [ [1,1,1]; cmap];
            
            mapped_data = ind2rgb(data,cmap);
            
        end
        
        function cscale = colourscale(obj,param)
            
            param_name = obj.fit_controller.fit_result.params{param};
            invert = obj.fit_controller.invert_colormap;
            
            if strcmp(param_name,'I0') || strcmp(param_name,'I')
                cscale = @gray;
            elseif invert && (~isempty(strfind(param_name,'tau')) || ~isempty(strfind(param_name,'theta')) || ~isempty(strfind(param_name,'r_ss')) )
                cscale = @inv_jet;
            else
                cscale = @jet;
            end
            
        end
        
        function im_data = plot_figure(obj,h,hc,dataset,param,merge,text)

            if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
                return
            end
            
            f = obj.fit_controller;

            intensity = f.get_intensity(dataset,'result');
            im_data = f.get_image(dataset,param,'result');

            
            cscale = obj.colourscale(param);

            lims = f.get_cur_lims(param);
            I_lims = f.get_cur_intensity_lims;
            if ~merge
                im=colorbar_flush(h,hc,im_data,isnan(intensity),lims,cscale,text);
            else
                im=colorbar_flush(h,hc,im_data,[],lims,cscale,text,intensity,I_lims);
            end
            

            if get(h,'Parent')==obj.plot_handle
                set(im,'uicontextmenu',obj.contextmenu);
            end
            
        end
       
    end
    
end