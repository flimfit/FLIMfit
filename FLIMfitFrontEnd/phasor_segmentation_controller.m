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
            edges = linspace(0,1,256);
            ed = edges(2:255);
            obj.phasor_im = imagesc(ed,ed,ones(256,256),'Parent',obj.phasor_axes);
            daspect(obj.phasor_axes,[1 1 1])
            set(obj.phasor_axes,'YDir','normal','XTick',[],'YTick',[]);

            hold(obj.phasor_axes,'on');
            theta = linspace(0,pi,1000);
            c = 0.5*(cos(theta) + 1i * sin(theta)) + 0.5;
            plot(obj.phasor_axes,real(c), imag(c) ,'w');


            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@(~,~) escaped_callback(@obj.selection_updated));
            
        end

        function update_display(obj)
            
            if isempty(obj.segmentation_axes) || ~ishandle(obj.segmentation_axes) || ~obj.data_series.init
                return
            end
            
            
            m = 256;

            selected = obj.data_series_list.selected;

            %trim_outliers = get(obj.trim_outliers_checkbox,'Value');

            cim = obj.data_series_controller.selected_intensity(selected,false);
            d = obj.data_series_controller.data_series;

            
            cim = uint8(255 * cim / prctile(cim(:),99));
            cim = repmat(cim,[1 1 3]);
            
            set(obj.segmentation_im,'CData',cim);
            set(obj.segmentation_axes,'XLim',[1 size(cim,2)],'YLim',[1 size(cim,1)]);
            
            p_irf = CalculatePhasor(d.tr_t_irf,d.tr_irf);
            
            
            [p,I] = CalculatePhasor(d.t,d.cur_data,p_irf);
            
            
            kern = ones(3,3);
            kern = kern / sum(kern(:));
            pr = conv2(squeeze(real(p)),kern,'same');
            pi = conv2(squeeze(imag(p)),kern,'same');
            p = pr + 1i * pi;
            p = reshape(p,[1 size(p)]);
            
            DrawPhasor(p,I,obj.phasor_im);

            
        end
        
        function on_callback(obj,src,evt)
            toggles = [obj.tool_roi_rect_toggle 
               obj.tool_roi_poly_toggle
               obj.tool_roi_circle_toggle
               obj.tool_roi_paint_toggle];
            toggle_type = {'rect','poly','ellipse',obj.brush_width};
            toggle_fcn = {@flex_roi,@flex_roi,@flex_roi,@paint_roi};

            sz = size(obj.mask);
            sz = sz(1:2);

            if strcmp(src.State,'on')
                set(toggles(toggles ~= src),'State','off');

                toggle_fcn = toggle_fcn{toggles == src};
                obj.flex_h = toggle_fcn(obj.figure1,obj.phasor_axes,toggle_type{toggles == src},sz,@obj.roi_callback);
                obj.toggle_active = src;
            else
                if obj.toggle_active == src && ~isempty(obj.flex_h)
                    delete(obj.flex_h)
                end
            end
    
            
            
        end
        
        function roi_callback(obj,roi_mask)
            modifier = get(gcbf,'currentmodifier');
            erase_toggle = get(obj.tool_roi_erase_toggle,'State');
            erase = strcmp(erase_toggle,'on') || ~isempty(modifier);

            obj.n_regions = obj.n_regions + 1;

            d = obj.data_series;
            
            % ...

            obj.update_display();

            delete(obj.flex_h);
            obj.flex_h = [];
        end
            
            
        
        function ok_pressed(obj,src,evt)
        end
        
        function cancel_pressed(obj,src,evt)
            delete(obj.figure1);
        end
        
        function data_update(obj)
            
        end
        
        function selection_updated(obj) 
            obj.update_display(); 
        end
        
    end
    
end

