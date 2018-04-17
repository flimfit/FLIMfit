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
                
        segmentation_im;
                
        ok_button;
        cancel_button;
        figure1;
                                
        toggle_active;
        flex_h;
        
        dataset = struct();
        
        histograms = segmentation_correlation_display.empty;
                
        slh = [];
        
        xml;
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
            
            obj.selection_updated();
            
            settings_file = obj.data_series_controller.data_series.multid_filters_file;
            if exist(settings_file,'file')
                obj.load_settings(settings_file);
            else
                obj.add_correlation();                
            end
            
            obj.update_display();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@(~,~) EC(@obj.selection_updated));
            
        end
        
        function add_correlation(obj)
            obj.histograms(end+1) = segmentation_correlation_display(obj, obj.panel_layout);
        end
        
        function calculate(obj)
           
            d = obj.data_series_controller.data_series;

            p_irf = CalculatePhasor(d.tr_t_irf,d.tr_irf);
            [p,I] = CalculatePhasor(d.t,d.cur_data,p_irf);
            
            acceptor = 0;
            if ~isempty(d.acceptor)
                acceptor = d.acceptor(:,:,d.active);
            end
            
            kern = ones(5,5);
            kern = kern / sum(kern(:));
            obj.dataset.p_r = conv2(squeeze(real(p)),kern,'same');
            obj.dataset.p_i = conv2(squeeze(imag(p)),kern,'same');
            obj.dataset.intensity = squeeze(I);
            obj.dataset.acceptor = acceptor;
            obj.dataset.phasor_lifetime = d.rep_rate ./ (2*pi) .* obj.dataset.p_i ./ obj.dataset.p_r;
            
            for h=obj.histograms
                h.update();
            end
            
        end

        function update_display(obj)
            
            if isempty(obj.segmentation_axes) || ~ishandle(obj.segmentation_axes) || ~obj.data_series.init
                return
            end
            
            selected = obj.data_series_list.selected;

            %trim_outliers = get(obj.trim_outliers_checkbox,'Value');

            cim = obj.data_series_controller.selected_intensity(selected,false);
            
            cim = uint8(255 * cim / prctile(cim(:),99));
            cim = repmat(cim,[1 1 3]);
            
            set(obj.segmentation_im,'CData',cim);
            set(obj.segmentation_axes,'XLim',[1 size(cim,2)],'YLim',[1 size(cim,1)]);

            m = obj.get_mask();
            
            im_mask = zeros(size(cim));
            im_mask(:,:,1) = 255;

            m = repmat(m,[1 1 3]);
            cim(~m) = im_mask(~m);
            
            set(obj.segmentation_im,'CData',cim);
            set(obj.segmentation_axes,'XLim',[1 size(cim,2)],'YLim',[1 size(cim,1)]);

            for h=obj.histograms
                h.update()
            end
            
        end
                   
        function mask = get_mask(obj)
            mask = true;
            for i=1:length(obj.histograms)
                if isvalid(obj.histograms(i)) && ~isempty(obj.histograms(i).mask)
                    mask = mask & obj.histograms(i).mask;
                end
            end
        end
        
        function ok_pressed(obj,~,~)
            
            d = obj.data_series_controller.data_series;

            % Save filters
            obj.save_settings(d.multid_filters_file);
            
            d.multid_mask = zeros([d.height d.width d.n_datasets],'uint8');
            
            % Apply filters to all datasets
            hb = waitbar(0,'Segmenting...');
            for i=1:d.n_datasets
                d.switch_active_dataset(i);
                obj.calculate();
                mask = obj.get_mask();
                d.multid_mask(:,:,i) = mask;
                waitbar(i/d.n_datasets,hb);
            end
            close(hb);
            
            delete(obj.figure1);            
        end
        
        function cancel_pressed(obj,~,~)
            delete(obj.figure1);
        end
        
        function data_update(obj)
            
        end
        
        function save_settings(obj, filename)
            doc = [];
            for i=1:length(obj.histograms)
                if isvalid(obj.histograms(i))
                    info = obj.histograms(i).get_info();
                    doc = serialise_object(info,doc,'correlation_filter');
                end
            end
            xmlwrite(filename, doc);
        end
        
        function load_settings(obj, filename)
            % Load new filtes from file
            h = marshal_struct(filename,'correlation_filter');
            
            % Remove old filters
            for i=1:length(obj.histograms)
                obj.histograms.remove();
            end
            
            % Load filters into correlation plots
            obj.histograms = segmentation_correlation_display.empty;
            for i=1:length(h)
                obj.add_correlation();
                obj.histograms(end).set_info(h(i));
            end
        end
        
        function selection_updated(obj) 
            d = obj.data_series_controller.data_series;
            selected = obj.data_series_list.selected;
            d.switch_active_dataset(selected);

            
            obj.calculate();
            obj.update_display(); 
        end
        
    end
    
end

