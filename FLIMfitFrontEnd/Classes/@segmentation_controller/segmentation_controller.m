classdef segmentation_controller < flim_data_series_observer
    
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
        funcs;
        param_list;
        default_list;
        desc_list;
        summary_list;
        
        tool_roi_rect_toggle;
        tool_roi_poly_toggle;
        tool_roi_circle_toggle;
        tool_roi_erase_toggle;
        
        replicate_mask_checkbox;
                
        algorithm_popup;
        parameter_table;
        segmentation_axes;
        segment_button;
        segment_selected_button;
        seg_results_table;
        seg_use_multiple_regions;
        
        delete_all_button;
        copy_to_all_button;
        
       
        trim_outliers_checkbox;
        
        data_series_list;
        
        waiting = false;
        
        selected = 1;
        
        segmentation_im;
        mask_im;
        
        mask = uint8(1);
        filtered_mask = uint8(1);
        n_regions = 0;
        
        ok_button;
        cancel_button;
        
        region_filter_table;
        combine_regions_checkbox;
        apply_filtering_pushbutton;
                
        filters = {'Min. Intensity LQ';'Min. Acceptor UQ';'Min. Size';'Max. Roundness Factor'};
        
        
        slh = [];
    end
    
    methods
        
        function obj = segmentation_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);

            set(obj.algorithm_popup,'Callback',@obj.algorithm_updated);
            set(obj.segment_button,'Callback',@obj.segment_pressed);
            set(obj.segment_selected_button,'Callback',@obj.segment_selected_pressed);
            set(obj.seg_results_table,'CellEdit',@obj.seg_results_delete);
            
            set(obj.apply_filtering_pushbutton,'Callback',@obj.apply_filtering_pressed);
            
            
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
            
            set(obj.trim_outliers_checkbox,'Callback',@(~,~) obj.update_display)
            
            
            filter_data = [num2cell(false(size(obj.filters))), ...
                           obj.filters, ...
                           num2cell(zeros(size(obj.filters)))];
                           
            set(obj.region_filter_table,'Data',filter_data);
            set(obj.region_filter_table,'ColumnEditable',[true false true]);
                        
            if ~isdeployed
            
                folder = [pwd filesep 'SegmentationFunctions'];
                addpath(folder);
                addpath([folder filesep 'Support']);

                [funcs, param_list, default_list, desc_list summary_list] = parse_function_folder(folder);
                
                save('segmentation_funcs.mat', 'funcs', 'param_list', 'default_list', 'desc_list', 'summary_list');
                
            else
                
                try 
                    load('segmentation_funcs.mat');
                catch %ok
                    funcs = [];
                    param_list = [];
                    default_list = [];
                    desc_list = [];
                    summary_list = [];
                end
                
            end
            
            obj.funcs = funcs;
            obj.param_list = param_list;
            obj.default_list = default_list;
            obj.desc_list = desc_list;
            obj.summary_list = summary_list;
            
            set(obj.algorithm_popup,'String',obj.funcs);
            
            if ispref('GlobalAnalysisFrontEnd','LastSegmentationParams')
                last_segmentation = getpref('GlobalAnalysisFrontEnd','LastSegmentationParams');
                set(obj.algorithm_popup,'Value',last_segmentation.func_idx);
                obj.algorithm_updated([],[]);
                set(obj.parameter_table,'Data',last_segmentation.params);
            else
                obj.algorithm_updated([],[]);
            end


            
            
            if ~isempty(obj.data_series.seg_mask)
                obj.mask = obj.data_series.seg_mask;
                obj.filtered_mask = obj.data_series.seg_mask;
            end
            
            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@obj.selection_updated);

        end
        
        function ok_pressed(obj,src,~)
            if all(obj.mask(:)==0)
                obj.mask = [];
                obj.filtered_mask = [];
            end
            
            
            obj.data_series.seg_mask = obj.filtered_mask;
            
            obj.save_segmentation_params();
            fh = ancestor(src,'figure');
            delete(fh);
        end
        
        function cancel_pressed(obj,src,~)
            obj.save_segmentation_params();
            fh = ancestor(src,'figure');         
            delete(fh);
        end
        
        function save_segmentation_params(obj)
            func_idx = get(obj.algorithm_popup,'Value');
            params = get(obj.parameter_table,'Data');

            last_segmentation = struct();
            last_segmentation.func_idx = func_idx;
            last_segmentation.params = params;
            setpref('GlobalAnalysisFrontEnd','LastSegmentationParams',last_segmentation);
        end
        
        function selection_updated(obj,src,~) 
            obj.update_display(); 
        end
        
        function data_update(obj)
            d = obj.data_series;
            obj.mask = zeros([d.height d.width d.n_datasets],'uint8');
            obj.update_display();
            obj.n_regions = 0;
        end
        
        function segment_pressed(obj,~,~)
            obj.segment(1:obj.data_series.n_datasets);
        end
        
        function segment_selected_pressed(obj,~,~)
            obj.segment(obj.data_series_list.selected);
        end
        
        function delete_all_pressed(obj,~,~)
            a = questdlg('Are you sure you want to clear all regions?','Confirmation','Yes','No','No');
            if strcmp(a,'Yes')
                d = obj.data_series;
                obj.mask = zeros([d.height d.width d.n_datasets],'uint8');
                obj.filter_masks(1:obj.data_series.n_datasets);
            end
        end
        
        function copy_to_all_pressed(obj,~,~)
            a = questdlg('Are you sure you want to copy to all datasets?','Confirmation','Yes','No','No');
            if strcmp(a,'Yes')
                m = obj.mask(:,:,obj.data_series_list.selected);
                for i=1:size(obj.mask,3)
                    obj.mask(:,:,i) = m;
                end
                obj.filter_masks(1:obj.data_series.n_datasets);
            end
        end
           
        function apply_filtering_pressed(obj,~,~)
            obj.filter_masks(1:obj.data_series.n_datasets);
        end
        
        function filter_masks(obj,sel)
            
            d = obj.data_series;
            
            filter_data = get(obj.region_filter_table,'Data');
            combine_regions = get(obj.combine_regions_checkbox,'Value');
            
            apply_filter = cell2mat(filter_data(:,1));
            filter_value = cell2mat(filter_data(:,3));
            
            donor_lq = [];
            acceptor_uq = [];
            min_size = [];
            
            max_shape_factor = [];
            
            if apply_filter(1)
                donor_lq = filter_value(1);
            end
            if apply_filter(2)
                acceptor_uq = filter_value(2);
            end
            if apply_filter(3)
                min_size = filter_value(3);
            end
            if apply_filter(4)
                max_shape_factor = filter_value(4);
            end
            
            
            if ndims(obj.mask) ~= ndims(obj.filtered_mask) || any(size(obj.mask) ~= size(obj.filtered_mask))
                obj.filtered_mask = obj.mask;
            end
            
            if length(sel) > 1
                h = waitbar(0,'Filtering Regions...');
            else
                h = [];
            end
            idx = 0;
            for i=sel
                
                im_mask = obj.mask(:,:,i); 

                if max(im_mask(:)) > 0
                    intensity = obj.data_series.integrated_intensity(i);
                    intensity(intensity<0) = 0;

                    if ~isempty(d.acceptor)
                        acceptor = d.acceptor(:,:,i);
                        acceptor(acceptor<0) = 0;
                    else
                        acceptor = [];
                    end


                    regions = regionprops(im_mask, {'Area','Perimeter'});


                    for j=1:length(regions)
                        j_mask = im_mask == j;

                        if ~isempty(donor_lq)
                            lq = double(prctile(intensity(j_mask),25));                
                            if lq<donor_lq
                                im_mask(j_mask) = 0;
                            end
                        end

                        if ~isempty(acceptor) && ~isempty(acceptor_uq)

                            uq = double(prctile(acceptor(j_mask),75));
                            if uq < acceptor_uq
                                im_mask(j_mask) = 0;
                            end

                        end

                        if ~isempty(min_size) && regions(j).Area < min_size
                            im_mask(j_mask) = 0;
                        end
                        
                        if ~isempty(max_shape_factor)                            
                            sf = (regions(j).Perimeter)^2/regions(j).Area/4/pi;
                            if sf < max_shape_factor
                                im_mask(j_mask) = 0;
                            end
                        end
                        
                    end


                    im_mask = im_mask > 0;

                    if ~combine_regions
                        im_mask = bwlabel(im_mask);
                    end

                end
                if ~isempty(im_mask)
                    obj.filtered_mask(:,:,i) = uint8(im_mask);
                end
                
                idx = idx + 1;
                if ~isempty(h)
                    waitbar(idx/length(sel),h);
                end
            end
            
            if ~isempty(h)
                close(h);
            end
            
            if any(obj.data_series_list.selected == sel)
                obj.update_display();
            end
            
        end
        
        function segment(obj,sel)
            func_idx = get(obj.algorithm_popup,'Value');
            func = obj.funcs{func_idx};
            params = get(obj.parameter_table,'Data');
            
            d = obj.data_series;
            h = waitbar(0,'Segmenting Images...');
            
            for i=sel
                intensity = d.integrated_intensity(i);
                intensity(intensity<0) = 0;
                
                im_mask = call_arb_segmentation_function(func,intensity,params);
                
                obj.mask(:,:,i) = uint8(im_mask);
               
                obj.filter_masks(i);
                
                waitbar(i/length(sel),h);
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
            obj.filter_masks(obj.data_series_list.selected);
            
        end
       
        
        function algorithm_updated(obj,~,~)
            idx = get(obj.algorithm_popup,'Value');
                params = obj.param_list{idx};
                default_values = obj.default_list{idx};
                desc = obj.desc_list{idx};
                summary = obj.summary_list{idx};
            
            tooltip = ['<html><font color="blue"><b>' summary '</b></font><br>'];
            for i=1:length(params)
                if ~strcmp(desc{i},'')
                    tooltip = [tooltip '<b>' params{i} '</b>: ' desc{i}];
                    tooltip = [tooltip '<br/>'];
                end
            end
            tooltip = [tooltip '</html>'];
            
            set(obj.parameter_table, 'tooltipString', tooltip);
            
            
            set(obj.parameter_table,'Data',default_values);
            set(obj.parameter_table,'RowName',params);
        end
                        
    end
    
end