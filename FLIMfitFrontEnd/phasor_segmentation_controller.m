classdef phasor_segmentation_controller < flim_data_series_observer
  
    properties
        
        menu_file_load_segmentation;
        menu_file_save_segmentation;
        menu_file_load_single_segmentation;
        
        tool_roi_rect_toggle;
        tool_roi_poly_toggle;
        tool_roi_circle_toggle;
        tool_roi_erase_toggle;
        tool_roi_paint_toggle;
        
        segmentation_axes;
        phasor_axes;
                               
        trim_outliers_checkbox;
        
        data_series_list;
                
        selected = 1;
        
        segmentation_im;
        phasor_im;
        mask_im;
        
        brush_width = 5;
        
        mask = uint16(1);
        filtered_mask = uint16(1);
        n_regions = 0;
        
        ok_button;
        cancel_button;
        figure1;
                                
        toggle_active;
        flex_h;
        
        slh = [];
    end
    
    methods
        
        function obj = phasor_segmentation_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);
            
%{            
            set(obj.algorithm_popup,'Callback',@obj.algorithm_updated);
            set(obj.segment_button,'Callback',@obj.segment_pressed);
            set(obj.segment_selected_button,'Callback',@obj.segment_selected_pressed);
            set(obj.seg_results_table,'CellEdit',@obj.seg_results_delete);
            
            set(obj.apply_filtering_pushbutton,'Callback',@obj.apply_filtering_pressed);            
%}
            
            set(obj.ok_button,'Callback',@obj.ok_pressed);
            set(obj.cancel_button,'Callback',@obj.cancel_pressed);
            
            % attempt to get Close request to behave as "cancel"
            set(obj.figure1,'CloseRequestFcn',@obj.cancel_pressed);
                        
            set(obj.tool_roi_rect_toggle,'State','off');
            set(obj.tool_roi_poly_toggle,'State','off');
            set(obj.tool_roi_circle_toggle,'State','off');
            set(obj.tool_roi_paint_toggle,'State','off');
                       
            set(obj.tool_roi_rect_toggle,'OnCallback',@obj.on_callback,'OffCallback',@obj.on_callback);
            set(obj.tool_roi_poly_toggle,'OnCallback',@obj.on_callback,'OffCallback',@obj.on_callback);
            set(obj.tool_roi_circle_toggle,'OnCallback',@obj.on_callback,'OffCallback',@obj.on_callback);
            set(obj.tool_roi_paint_toggle,'OnCallback',@obj.on_callback,'OffCallback',@obj.on_callback);
            
%            set(obj.trim_outliers_checkbox,'Callback',@(~,~) obj.update_display)
%{            
            set(obj.menu_file_load_segmentation,'Callback',@(~,~) obj.load_segmentation);
            set(obj.menu_file_load_single_segmentation,'Callback',@(~,~) obj.load_single_segmentation);
            set(obj.menu_file_save_segmentation,'Callback',@(~,~) obj.save_segmentation);
            set(obj.OMERO_Load_Segmentation_Images,'Callback',@(~,~) obj.load_segmentation_OMERO);
            set(obj.OMERO_Load_Single_Segmentation_Image,'Callback',@(~,~) obj.load_single_segmentation_OMERO);
            set(obj.OMERO_Save_Segmentation_Images,'Callback',@(~,~) obj.save_segmentation_OMERO);
            set(obj.OMERO_Remove_Segmentation,'Callback',@(~,~) obj.remove_segmentation_OMERO);
            set(obj.OMERO_Remove_All_Segmentations,'Callback',@(~,~) obj.remove_all_segmentations_OMERO);
%}          
%            set(obj.brush_width_popup,'Callback',@(~,~) obj.set_brush_width);
            
%{            
            if ispref('GlobalAnalysisFrontEnd','LastSegmentationParams')
                last_segmentation = getpref('GlobalAnalysisFrontEnd','LastSegmentationParams');
                set(obj.algorithm_popup,'Value',last_segmentation.func_idx);
                obj.algorithm_updated([],[]);
                set(obj.parameter_table,'Data',last_segmentation.params);
            else
                obj.algorithm_updated([],[]);
            end
  %}                      
            obj.segmentation_im = image(0,'Parent',obj.segmentation_axes);
            set(obj.segmentation_axes,'XTick',[],'YTick',[]);
            daspect(obj.segmentation_axes,[1 1 1]);
            
            obj.phasor_im = image(0,'Parent',obj.phasor_axes);
            set(obj.phasor_axes,'XTick',[],'YTick',[]);
            daspect(obj.phasor_axes,[1 1 1]);

            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@(~,~) escaped_callback(@obj.selection_updated));
            
        end

        function update_display(obj)
        end
        
        function on_callback(obj,evt)
            
        end
        
        function ok_pressed(obj,src,evt)
        end
        
        function cancel_pressed(obj,src,evt)
            delete(obj.figure1);
        end
        
        function data_update(obj)
        end
        
    end
    
end

