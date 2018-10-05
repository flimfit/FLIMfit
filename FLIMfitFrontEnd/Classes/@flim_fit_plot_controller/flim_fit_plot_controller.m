 classdef flim_fit_plot_controller < handle
     
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
        dataset_selected = 1;       
        plot_panel;
        plot_axes;
    
        n_plots = 0;
        
        result_controller;
        data_series_list;
        lh = {};
    end
    
    properties(Access='protected')
        n_exp_list = 0;
        n_fret_list = 0;
        inc_donor_list = 0;
    end
    
    methods
       
        function obj = flim_fit_plot_controller(handles)
                                   
            assign_handles(obj,handles);
            
            set(obj.plot_panel,'ResizeFcn',@obj.panel_resized);
            addlistener(obj.data_series_list,'selection_updated',@(src,evt) EC(@obj.dataset_selected_update,src,evt));
            addlistener(obj.result_controller,'result_updated',@(src,evt) EC(@obj.result_updated));
            addlistener(obj.result_controller,'result_display_updated',@(src,evt) EC(@obj.result_updated));
            
            
        end
        
        function export_plots(obj,file_root)
            obj.update_plots(file_root);
        end
        
        
        function panel_resized(obj,~,~)
            obj.update_plots();
        end
        
        function lims = get_lims(~,var)
            var = var(:);
            lims = [min(var) max(var)];
        end
        
        
        function dataset_selected_update(obj,src,~)          
            obj.dataset_selected = src.selected;
            obj.update_plots();
        end
        
        function result_updated(obj)
            if ishandle(obj.plot_panel) %check object hasn't been closed
                obj.update_plots();
            end
        end
       
    end
    
end