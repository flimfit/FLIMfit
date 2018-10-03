classdef flim_fit_controller < flim_data_series_observer
    
    
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
        fit_result;
        
        fitting_params_controller;
        roi_controller;
        data_series_list;
        fit_params;
                
        binned_fit_pushbutton;
        fit_pushbutton;
        progress_table;
        
        dll_interface;
               
        progress_cur_group;
        progress_n_completed
        progress_iter;
        progress_chi2;
        progress;
        
        has_fit = false;
        fit_in_progress = false;
        terminating = false;
        
        wait_handle;
        cur_fit;
        start_time;
        
        selected;
         
        lh = {};
    end
    
    events
        progress_update;
        fit_updated;
        fit_display_updated;
        fit_completed;
    end
        
    
    methods
                
        function obj = flim_fit_controller(varargin)
            
            if nargin < 1
                handles = struct('data_series_controller',[]);
            else
                handles = args2struct(varargin);
            end
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
                        
            obj.dll_interface = flim_dll_interface();
            
            set(obj.fit_pushbutton,'Callback',@(~,~) EC(@obj.fit_pushbutton_callback));
            set(obj.binned_fit_pushbutton,'Callback',@(~,~) EC(@obj.binned_fit_pushbutton_callback));
            
            if ~isempty(obj.data_series_controller) 
                addlistener(obj.data_series_controller,'new_dataset',@(~,~) EC(@obj.new_dataset));
            end
            
            addlistener(obj.dll_interface,'fit_completed',@(~,~) EC(@obj.fit_complete));
            addlistener(obj.dll_interface,'progress_update',@(~,~) EC(@obj.update_progress));
            
            if ~isempty(obj.fitting_params_controller)
                addlistener(obj.fitting_params_controller,'fit_params_update',@(~,~) EC(@obj.fit_params_updated));
                obj.fit_params = obj.fitting_params_controller.fit_params;
            end
            
            if ~isempty(obj.roi_controller)
                addlistener(obj.roi_controller,'roi_updated',@(~,~) EC(@obj.roi_mask_updated));
            end

        end       
        
        function fit_params_updated(obj)
            obj.fit_params = obj.fitting_params_controller.fit_params;
            obj.has_fit = false;
        end
        
        function roi_mask_updated(obj)
            if (obj.has_fit && obj.fit_result.binned) 
                obj.clear_fit();
            end
        end
                
        function lims = get_cur_intensity_lims(obj,param)      
            param = obj.get_intensity_idx(param);
            lims = obj.get_cur_lims(param);     
        end
        
        function lims = set_cur_lims(obj,param,lims)
            obj.cur_lims(param,:) = lims;
        end
                
        function fit_pushbutton_callback(obj)
            obj.fit();
        end
        
        function binned_fit_pushbutton_callback(obj)
            obj.fit(true);
        end
        
        function data_update(obj)
        end
        
        function new_dataset(obj)
        end
        
        function decay = fitted_decay(obj,t,im_mask,selected)
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series') && ~isempty(obj.data_series_controller.data_series.fitted_data)
                decay = NaN;
            else            
                decay = obj.dll_interface.fitted_decay(im_mask,selected);
            end

        end
        
        function anis = fitted_anisotropy(obj,t,im_mask,selected)
            decay = obj.fitted_decay(im_mask,selected);
            
            d = obj.data_series;
            
            para = decay(:,1);
            perp = decay(:,2);
            perp_shift = obj.data_series.shifted_perp(perp) * d.g_factor;
            
            anis = (para-perp_shift)./(para+2*perp_shift);
                       
            parac = conv(para,d.tr_irf(:,2));
            perpc = conv(perp,d.tr_irf(:,1));
            [~,n] = max(d.tr_irf(:,1));
            anis = (parac-perpc)./(parac+2*perpc);
            anis = anis((1:size(decay,1))+n,:);
        end
        
        function magic = fitted_magic_angle(obj,t,im_mask,selected)
            decay = obj.fitted_decay(im_mask,selected);
            
            para = decay(:,1);
            perp = decay(:,2);
            perp_shift = obj.data_series.shifted_perp(perp) * obj.data_series.g_factor;

            irf = obj.data_series.tr_irf;
            
            parac = conv(para,irf(:,2));
            perpc = conv(perp,irf(:,1));

            [~,n] = max(irf(:,1));
             magic = (parac+2*perpc);
            
            magic = magic((1:size(decay,1))+n,:);
        end
        
        function display_fit_end(obj)
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'String','Fit Dataset');  
            end
            
            if ~isempty(obj.wait_handle)
                delete(obj.wait_handle)
                obj.wait_handle = [];       % delete seems to leave an invalid obj in the class so replace
            end
        end
        
        function display_fit_start(obj)
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'String','Stop Fit');
                if obj.use_popup
                    obj.wait_handle = ProgressDialog('Indeterminate', true, 'StatusMessage', 'Fitting...'); %waitbar(0,'Fitting...');
                    obj.dll_interface.progress_bar = obj.wait_handle;
                end
            end
        end
        
    end
end