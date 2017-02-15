classdef flim_fitting_params_controller < control_binder & flim_data_series_observer
   
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
        bound_all_controls = false;
                
        fit_controller;
        
        fit_params;
    end
    
    events
        fit_params_update;
    end
    
    methods
             
       
        function obj = flim_fitting_params_controller(handles)

            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@control_binder(flim_fitting_params());
            
            
            assign_handles(obj,handles);

            obj.fit_params = obj.bound_data_source;                                
            obj.bind_control(handles,'weighting_mode','popupmenu');
            obj.bind_control(handles,'calculate_errs','checkbox');
            obj.bind_control(handles,'n_thread','edit');
            obj.bind_control(handles,'global_scope','popupmenu');
            obj.bind_control(handles,'image_irf_mode','popupmenu');
            obj.bind_control(handles,'fitting_algorithm','popupmenu');
            
            obj.bound_all_controls = true;
            obj.set_polarisation_mode(false);
            obj.fit_params.model = handles.model_controller.model;
            
			addlistener(obj.data_series_controller,'new_dataset',@(~,~) escaped_callback(@obj.data_update_evt));
            
            obj.update_controls();
            
        end
        
        function data_update(obj)
            
            if obj.data_series.init
                obj.set_polarisation_mode(obj.data_series.polarisation_resolved);
            end
            
        end
        
        function load_fitting_params(obj,file)
            try 
                doc_node = xmlread(file);
                obj.fit_params = marshal_object(doc_node,'flim_fitting_params',obj.fit_params);
                obj.update_controls();
                notify(obj,'fit_params_update');
            catch
                warning('FLIMfit:LoadDataSettingsFailed','Failed to load data settings file'); 
            end
            
        end
        
        function save_fitting_params(obj,file)
            obj.fit_params.save_fitting_params(file);
        end
        
        function set_polarisation_mode(obj,polarisation_resolved)
           
            obj.fit_params.polarisation_resolved = polarisation_resolved;
                        
        end
        
        
                
        function update_controls(obj)
            
            if ~obj.bound_all_controls
                return
            end
            notify(obj,'fit_params_update');
            
        end
        
    end
    
end