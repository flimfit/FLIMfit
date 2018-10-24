classdef phasor_segmentation_controller < flim_data_series_observer
  
    properties
        
        menu_file_export_phasor_images;
        menu_file_export_backgated_image;
        
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
        n_chan;
        
        histograms = segmentation_correlation_display.empty;
                
        slh = [];
        
        xml;
    end
    
    methods
        
        function obj = phasor_segmentation_controller(handles)
            
            obj = obj@flim_data_series_observer(handles.data_series_controller);      
            assign_handles(obj,handles);
            obj.data_series_list.set_source(obj.data_series);
            
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

            set(obj.menu_file_export_phasor_images,'Callback',@obj.export_phasor_callback);
            set(obj.menu_file_export_backgated_image,'Callback',@obj.export_backgated_callback);
            
            obj.segmentation_im = image(0,'Parent',obj.segmentation_axes);
            set(obj.segmentation_axes,'XTick',[],'YTick',[]);
            daspect(obj.segmentation_axes,[1 1 1]);
            
            obj.calculate();
            
            settings_file = obj.data_series_controller.data_series.multid_filters_file;
            if exist(settings_file,'file')
                obj.load_settings(settings_file);
            else
                for i=1:obj.n_chan
                    obj.add_correlation(i);                
                end
            end
            
            obj.selection_updated();
            obj.slh = addlistener(obj.data_series_list,'selection_updated',@(~,~) EC(@obj.selection_updated));
            
        end
        
        function add_correlation(obj, default_idx)
            if nargin >= 2
                x_name = ['p_r_' num2str(default_idx)];
                y_name = ['p_i_' num2str(default_idx)];

                obj.histograms(end+1) = segmentation_correlation_display(obj, obj.panel_layout, x_name, y_name);
            else
                obj.histograms(end+1) = segmentation_correlation_display(obj, obj.panel_layout);
            end
        end
        
        function calculate(obj)
           
            d = obj.data_series_controller.data_series;

            p_irf = CalculatePhasor(d.irf.tr_t_irf,d.irf.tr_irf);
            [p,I] = CalculatePhasor(d.t,d.cur_data,p_irf);
            sp = CalculateSpectralPhasor(I);
            
            acceptor = 0;
            if ~isempty(d.acceptor)
                acceptor = d.acceptor(:,:,d.active);
            end
                        
            kern = fspecial('disk',3);
            
            obj.n_chan = size(p,1);
                        
            for i=1:obj.n_chan
                ext = ['_' num2str(i)];
                p_r = conv2(squeeze(real(p(i,:,:))),kern,'same');
                p_i = conv2(squeeze(imag(p(i,:,:))),kern,'same');
                obj.dataset.(['p_r' ext]) = p_r;
                obj.dataset.(['p_i' ext]) = p_i;
                obj.dataset.(['phasor_lifetime' ext]) = d.rep_rate ./ (2*pi) .* p_i ./ p_r;
                obj.dataset.(['intensity' ext]) = squeeze(I(i,:,:));
            end
            for j=1:size(I,1)
                for k=(j+1):size(I,1)
                    obj.dataset.(['ratio_I' num2str(k) '_I' num2str(j)]) = squeeze(I(k,:,:) ./ I(j,:,:));
                end
            end
            
            obj.dataset.('s_r') = conv2(real(sp),kern,'same');
            obj.dataset.('s_i') = conv2(imag(sp),kern,'same');

            
            obj.dataset.total_intensity = squeeze(sum(I,1));
            obj.dataset.acceptor = acceptor;
            
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
            
            %im_mask = zeros(size(cim));
            %im_mask(:,:,1) = 255;

            m = repmat(m,[1 1 3]);
            
            m1 = m;
            m1(:,:,2:3) = 0;
            
            m2 = m;
            m2(:,:,1) = 0;

            
            cim(m1) = 255;
            
            cim(m2) = min(2*cim(m2),200);
            
            set(obj.segmentation_im,'CData',cim);
            set(obj.segmentation_axes,'XLim',[1 size(cim,2)],'YLim',[1 size(cim,1)]);

            for h=obj.histograms
                h.update()
            end
            
        end
        
        function export_phasor_callback(obj,~,~)
            default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            [file, path] = uiputfile('*.tif','Select file name',default_path);
            
            if file ~= 0
                for h = obj.histograms
                    im = h.get_histogram();
                    [x_name, y_name] = h.get_names();
                    h_file = strrep(file,'.tif',[' ' x_name ' vs ' y_name '.tif']);
                    imwrite(uint8(im*255),[path filesep h_file]);
                end
            end
        end
        
        function export_backgated_callback(obj,~,~)
            default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            name = obj.data_series_controller.data_series.names{obj.data_series_list.selected};

            [file, path] = uiputfile('*.tif','Select file name',[default_path name '-backgated.tif']);
            
            
            if file ~= 0
               imwrite(obj.get_mask(),[path filesep file]);            
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
            
            d.multid_mask = false([d.height d.width d.n_datasets]);
            
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

