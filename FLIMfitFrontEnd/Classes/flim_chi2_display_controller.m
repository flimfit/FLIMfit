classdef flim_chi2_display_controller < flim_fit_observer
    
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
        chi2_axes;
        display_factor_edit;
        calculate_button;
        
    end
    
    methods
        
        function obj = flim_chi2_display_controller(handles)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            assign_handles(obj,handles);

            set(obj.calculate_button,'Callback',@obj.calculate_clicked);
            set(obj.display_factor_edit,'Callback',@obj.display_factor_change);
             
        end
        
        function fit_update(obj)
            obj.update_plot();
        end
        
        function display_factor_change(obj,~,~)
            obj.update_plot();
        end
        
        function update_plot(obj)
            p = obj.fit_controller.fit_params;
            f = obj.fit_controller.fit_result;
            
            fact = str2double(get(obj.display_factor_edit,'String'));
            if obj.fit_controller.has_fit && f.has_grid
                nx = size(f.grid,1);
                ny = size(f.grid,2);
               
                x = (1:nx)/nx * (p.tau_max(1) - p.tau_min(1)) +  p.tau_min(1);
                y = (1:ny)/ny * (p.tau_max(2) - p.tau_min(2)) +  p.tau_min(2);
                imagesc(x,y,f.grid,'Parent',obj.chi2_axes);
                
                mn = min(f.grid(f.grid>0))+1e-3;
                mx = max(f.grid(f.grid>0));
                lm = [mn mn*fact];
                
                caxis(obj.chi2_axes,lm);
                colorbar('peer',obj.chi2_axes);
                
            end
        end
        
        function calculate_clicked(obj,~,~)
            obj.fit_controller.fit(true,true);
            
        end
        
    end
    
end

