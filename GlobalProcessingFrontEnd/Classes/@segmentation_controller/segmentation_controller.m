classdef segmentation_controller < flim_data_series_observer
   
    properties
        funcs;
        param_list;
        
        tool_roi_rect_toggle;
        tool_roi_poly_toggle;
        tool_roi_circle_toggle;
        
        replicate_mask_checkbox;
        
        pipeline_edit;
        cellprofiler_segment_button;
        
        algorithm_popup;
        parameter_table;
        segmentation_axes;
        yuiry_segment_button;
        seg_results_table;
        
        delete_all_button;
        copy_to_all_button;
        
        thresh_min_edit;
        thresh_max_edit;
        thresh_apply_button;
        
        
        data_series_list;
        
        waiting = false;
        
        selected = 1;
        
        segmentation_im;
        mask_im;
        
        mask = 1;
        n_regions = 0;
        
        ok_button;
        cancel_button;
        
        slh = [];
    end
    
    methods
        
        function obj = segmentation_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);

            set(obj.algorithm_popup,'Callback',@obj.algorithm_updated);
            set(obj.yuiry_segment_button,'Callback',@obj.yuiry_segment_pressed);
            set(obj.thresh_apply_button,'Callback',@obj.thresh_apply_pressed);
            set(obj.seg_results_table,'CellEdit',@obj.seg_results_delete);
            
            set(obj.ok_button,'Callback',@obj.ok_pressed);
            set(obj.cancel_button,'Callback',@obj.cancel_pressed);
            
            set(obj.delete_all_button,'Callback',@obj.delete_all_pressed);
            set(obj.copy_to_all_button,'Callback',@obj.copy_to_all_pressed);
            
            
            set(obj.tool_roi_rect_toggle,'State','off');
            set(obj.tool_roi_poly_toggle,'State','off');
            set(obj.tool_roi_circle_toggle,'State','off');
                       
            set(obj.tool_roi_rect_toggle,'OnCallback',@obj.on_callback);
            set(obj.tool_roi_poly_toggle,'OnCallback',@obj.on_callback);
            set(obj.tool_roi_circle_toggle,'OnCallback',@obj.on_callback);
            
                        
            if ~isdeployed
            
                folder = [pwd '\YuriySegmentation'];
                addpath(folder);
                addpath([folder '\Support']);

                [funcs, param_list] = parse_function_folder(folder);

                save('segmentation_funcs.mat', 'funcs', 'param_list');
                
            else
                
                try 
                    load('segmentation_funcs.mat');
                catch %ok
                    funcs = [];
                    param_list = [];
                end
                
            end
            
            obj.funcs = funcs;
            obj.param_list = param_list;
            
            set(obj.algorithm_popup,'String',obj.funcs);
            
            if ~isempty(obj.data_series.seg_mask)
                obj.mask = obj.data_series.seg_mask;
            end
            
            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@obj.selection_updated);

        end
        
        function ok_pressed(obj,src,~)
            if all(obj.mask(:)==0)
                obj.mask = [];
            end
            
            
            obj.data_series.seg_mask = obj.mask;
            
            
            fh = ancestor(src,'figure');
            delete(fh);
        end
        
        function cancel_pressed(obj,src,~)
            fh = ancestor(src,'figure');         
            delete(fh);
        end
        
        function selection_updated(obj,src,~) 
            obj.update_display(); 
        end
        
        function data_update(obj)
            d = obj.data_series;
            obj.mask = zeros([d.height d.width d.n_datasets],'uint8');
            obj.update_display();
        end
        
        function yuiry_segment_pressed(obj,~,~)
            obj.yuiry_segment();
        end
        
        function delete_all_pressed(obj,~,~)
            a = questdlg('Are you sure you want to clear all regions?','Confirmation','Yes','No','No');
            if strcmp(a,'Yes')
                d = obj.data_series;
                obj.mask = zeros([d.height d.width d.n_datasets]);
                obj.update_display();
            end
        end
        
        function copy_to_all_pressed(obj,~,~)
            a = questdlg('Are you sure you want to copy to all datasets?','Confirmation','Yes','No','No');
            if strcmp(a,'Yes')
                m = obj.mask(:,:,obj.data_series_list.selected);
                for i=1:size(obj.mask,3)
                    obj.mask(:,:,i) = m;
                end
            end
        end
                
        function yuiry_segment(obj)
            func_idx = get(obj.algorithm_popup,'Value');
            func = obj.funcs{func_idx};
            params = get(obj.parameter_table,'Data');
            params = num2cell(params);

            obj.mask = zeros(size(obj.data_series.mask),'uint8');
            h = waitbar(0,'Segmenting Images...');
            for i=1:obj.data_series.n_datasets
                obj.mask(:,:,i) = call_arb_segmentation_function(func,obj.data_series.selected_intensity(i,false),params);
                waitbar(i/obj.data_series.n_datasets,h);
            end
            close(h);
            
            obj.update_display();
        end
        
        function seg_results_delete(obj,~,~)
            table_data = get(obj.seg_results_table,'Data');
            del = table_data(:,3);           
            
            m = obj.mask(:,:,obj.data_series_list.selected);
            for j = length(del):-1:1
                if del{j}
                    m(m==j) = 0;
                    m(m>j) = m(m>j) - 1;
                    obj.n_regions = obj.n_regions - 1;
                end
            end
            obj.mask(:,:,obj.data_series_list.selected) = m;
            
            obj.update_display();
        end
        
        function thresh_apply_pressed(obj,~,~)
            sel = obj.data_series_list.selected;
            intensity = obj.data_series.intensity(:,:,sel);
            thresh_min = str2double(get(obj.thresh_min_edit,'String'));
            thresh_max = str2double(get(obj.thresh_max_edit,'String'));
            
            thresh = intensity >= thresh_min & intensity <= thresh_max;
            
            m = zeros(size(thresh));
            m(thresh) = 1;
            
            obj.mask(:,:,sel) = m;
            
            obj.update_display();
        end
        
        function algorithm_updated(obj,~,~)
            idx = get(obj.algorithm_popup,'Value');
            params = obj.param_list{idx};
            default_values = zeros(size(params));
            
            set(obj.parameter_table,'Data',default_values);
            set(obj.parameter_table,'RowName',params);
        end
                        
    end
    
end