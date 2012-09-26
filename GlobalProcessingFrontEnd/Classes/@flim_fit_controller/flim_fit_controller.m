classdef flim_fit_controller < flim_data_series_observer
   
    properties
        fit_result;
        
        fitting_params_controller;
        fit_params;
        
        roi_controller;
        data_series_list;
        
        binned_fit_pushbutton;
        fit_pushbutton;
        results_table;
        progress_table;
    
        filter_table;
        
        dll_interface;
        
        param_table;
        param_table_headers;
        
        live_update_checkbox;
        
        progress_cur_group;
        progress_n_completed
        progress_iter;
        progress_chi2;
        progress;
        
        has_fit = false;
        fit_in_progress = false;
        
        wait_handle;
        cur_fit;
        start_time;
        
        selected;
        
        live_update = false;
        refit_after_return = false;
        
        use_popup = false;
        
        lh = {};
                
    end
    
    events
        progress_update;
        fit_updated;
        fit_display_updated;
        fit_completed;
    end
        
    
    methods
        
        function delete(obj,src)
            a = 1;
        end
        
        function obj = flim_fit_controller(varargin)
            
            if nargin < 1
                handles = struct('data_series_controller',[]);
            else
                handles = args2struct(varargin);
            end
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);
            
            obj.fit_result = flim_fit_result();
            obj.dll_interface = flim_dll_interface();
            
            if ishandle(obj.fit_pushbutton)
                set(obj.fit_pushbutton,'Callback',@obj.fit_pushbutton_callback);
            end

            if ishandle(obj.binned_fit_pushbutton)
                set(obj.binned_fit_pushbutton,'Callback',@obj.binned_fit_pushbutton_callback);
            end

            
            if ~isempty(obj.data_series_controller) 
                addlistener(obj.data_series_controller,'new_dataset',@obj.new_dataset);
            end
            
            addlistener(obj.dll_interface,'fit_completed',@obj.fit_complete);
            addlistener(obj.dll_interface,'progress_update',@obj.update_progress);
            
            if ~isempty(obj.fitting_params_controller)
                addlistener(obj.fitting_params_controller,'fit_params_update',@obj.fit_params_updated);
                obj.fit_params = obj.fitting_params_controller.fit_params;
            end
            
            if ~isempty(obj.roi_controller)
                addlistener(obj.roi_controller,'roi_updated',@obj.roi_mask_updated);
            end
            
            if ~isempty(obj.live_update_checkbox)
                set(obj.live_update_checkbox,'Value',obj.live_update);
                set(obj.live_update_checkbox,'Callback',@obj.live_update_callback);
            end
            
        end       
        
        function fit_params_updated(obj,~,~)
            obj.fit_params = obj.fitting_params_controller.fit_params;
            if obj.data_series_controller.data_series.init && obj.live_update
                obj.fit(true);
            else
                obj.has_fit = false;
            end
        end
        
        function roi_mask_updated(obj,~,~)
            d = obj.data_series_controller.data_series;
            if ~(obj.has_fit && obj.fit_result.binned == false) && d.init
                if obj.live_update
                    obj.fit(true);
                else
                    obj.clear_fit();
                end
            end
        end
        
        function [param_data mask] = get_image(obj,im,param)
            [param_data mask] = obj.dll_interface.get_image(im,param);
        end
        
        function [param_data mask] = get_intensity(obj,im)
            param = obj.fit_result.intensity_idx;
            if ~isempty(param) 
                [param_data mask] = obj.dll_interface.get_image(im,param);
            else
                param_data = 0;
                mask = 0;
            end
        end
        
        
        function live_update_callback(obj,~,~)
            obj.live_update = get(obj.live_update_checkbox,'Value');
            if obj.live_update == false
                obj.clear_fit();
            end
        end
        
        function fit_pushbutton_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            if d.init
                obj.fit();
            end            
        end
        
        function binned_fit_pushbutton_callback(obj,~,~)
            d = obj.data_series_controller.data_series;
            if d.init
                obj.fit(true);
            end
        end
        
        function data_update(obj)
            obj.clear_fit();
        end
        
        function new_dataset(obj,~,~)
            obj.clear_fit();
        end
        
        function update_table(obj)
            if ishandle(obj.results_table)
                set(obj.results_table,'ColumnName','numbered');
                set(obj.results_table,'RowName',obj.param_table_headers);
                set(obj.results_table,'Data',obj.param_table);
                
                set(obj.progress_table,'RowName',obj.param_table_headers(1:5));
                set(obj.progress_table,'Data',obj.param_table(1:5,:));
            end
        end
        
        function decay = fitted_decay(obj,t,im_mask,selected)
            decay = obj.dll_interface.fitted_decay(t,im_mask,selected);
        end
        
        function anis = fitted_anisotropy(obj,t,im_mask,selected)
            decay = obj.fitted_decay(t,im_mask,selected);
            
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
            decay = obj.fitted_decay(t,im_mask,selected);
            
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
            
            if ishandle(obj.wait_handle)
                delete(obj.wait_handle)
            end
           
        end
        
        function display_fit_start(obj)
            
            if ishandle(obj.fit_pushbutton)
                %set(obj.fit_pushbutton,'BackgroundColor',[1 0.6 0.2]);
                set(obj.fit_pushbutton,'String','Stop Fit');
                if obj.use_popup
                    obj.wait_handle = waitbar(0,'Fitting...');
                end
            end
            
        end
        
        function update_filter_table(obj)
           
            md = obj.fit_result.metadata;
            
            data = get(obj.filter_table,'Data');
            
            if isempty(data)            
                empty_data = repmat({'','',''},[10 1]);
                
                set(obj.filter_table,'ColumnName',{'Param','Type','Value'})
                set(obj.filter_table,'Data',empty_data)
                set(obj.filter_table,'ColumnEditable',true(1,3));
                set(obj.filter_table,'CellEditCallback',@obj.filter_table_updated);
                set(obj.filter_table,'RowName',[]);
            end
            
            set(obj.filter_table,'ColumnFormat',{[{'-'} fieldnames(md)'],{'=','!=','<','>'},'char'})

            
        end
        
        
    end
    
end