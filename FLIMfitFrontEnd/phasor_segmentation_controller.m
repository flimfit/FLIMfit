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
        panel_layout;
                               
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
        
        dataset = struct();
        
        histograms = segmentation_correlation_display.empty;
                
        slh = [];
    end
    
    methods
        
        function obj = phasor_segmentation_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            
            assign_handles(obj,handles);
               
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
                                 
            obj.segmentation_im = image(0,'Parent',obj.segmentation_axes);
            set(obj.segmentation_axes,'XTick',[],'YTick',[]);
            daspect(obj.segmentation_axes,[1 1 1]);
            
            obj.calculate();
            
            obj.add_correlation();
            
            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@(~,~) escaped_callback(@obj.selection_updated));
            
        end
        
        function add_correlation(obj)
            obj.histograms(end+1) = segmentation_correlation_display(obj, obj.panel_layout);
        end
        
        function calculate(obj)
           
            d = obj.data_series_controller.data_series;

            p_irf = CalculatePhasor(d.tr_t_irf,d.tr_irf);
            [p,I] = CalculatePhasor(d.t,d.cur_data,p_irf);
            
            kern = ones(3,3);
            kern = kern / sum(kern(:));
            obj.dataset.p_r = conv2(squeeze(real(p)),kern,'same');
            obj.dataset.p_i = conv2(squeeze(imag(p)),kern,'same');
            obj.dataset.intensity = squeeze(I);
            obj.dataset.phasor_lifetime = d.rep_rate ./ (2*pi) .* obj.dataset.p_i ./ obj.dataset.p_r;
            
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

            m = true;
            for i=1:length(obj.histograms)
                if ~isempty(obj.histograms(i).mask)
                    m = m & obj.histograms(i).mask;
                end
            end
            
            im_mask = zeros(size(cim));
            im_mask(:,:,1) = 255;

            m = repmat(m,[1 1 3]);
            cim(~m) = im_mask(~m);
            
            set(obj.segmentation_im,'CData',cim);
            set(obj.segmentation_axes,'XLim',[1 size(cim,2)],'YLim',[1 size(cim,1)]);

            
        end
                   
            
        
        function ok_pressed(obj,src,evt)
        end
        
        function cancel_pressed(obj,src,evt)
            delete(obj.figure1);
        end
        
        function data_update(obj)
            
        end
        
        function selection_updated(obj) 
            obj.calculate();
            obj.update_display(); 
        end
        
    end
    
end

