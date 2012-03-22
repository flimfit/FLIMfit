classdef flim_data_masking_controller < handle & flim_data_series_observer
    
    properties
        roi_controller;
        data_series_list;
        fit_controller
       
        binning_popupmenu;
        downsampling_popupmenu;
        thresh_min_edit;
        gate_max_edit;
        t_min_edit;
        t_max_edit;
        t_irf_min_edit;
        t_irf_max_edit;
        irf_background_edit;
        g_factor_edit;
        afterpulsing_correction_checkbox;
        
        background_type_popupmenu;
        background_value_edit;
        tvb_popupmenu;
        tvb_define_pushbutton;
        
        irf_display_axes;
        background_axes;
        background_container;
        
        g_factor_guess_pushbutton;
        irf_background_guess_pushbutton;
        t0_guess_pushbutton;
        
        t0_edit;
        
        irf_lower_ann = [];
        irf_upper_ann = [];
        
        lh = {};
    end
       
    methods 
        function obj = flim_data_masking_controller(handles)
        
            obj = obj@flim_data_series_observer(handles.data_series_controller);
        
            assign_handles(obj,handles);
            
            set(obj.binning_popupmenu,'Callback',@obj.masking_callback);
            set(obj.downsampling_popupmenu,'Callback',@obj.masking_callback);
            set(obj.thresh_min_edit,'Callback',@obj.masking_callback);
            set(obj.gate_max_edit,'Callback',@obj.masking_callback);
            set(obj.t_min_edit,'Callback',@obj.masking_callback);
            set(obj.t_max_edit,'Callback',@obj.masking_callback);
            set(obj.t_irf_min_edit,'Callback',@obj.masking_callback);
            set(obj.t_irf_max_edit,'Callback',@obj.masking_callback);
            set(obj.irf_background_edit,'Callback',@obj.masking_callback);
            set(obj.g_factor_edit,'Callback',@obj.masking_callback);
            set(obj.afterpulsing_correction_checkbox,'Callback',@obj.masking_callback);
            set(obj.background_value_edit,'Callback',@obj.masking_callback);
            set(obj.background_type_popupmenu,'Callback',@obj.masking_callback);
            set(obj.t0_edit,'Callback',@obj.masking_callback);
            
            set(obj.irf_display_axes,'ButtonDownFcn',@obj.irf_plot_clicked);
            
            set(obj.irf_background_guess_pushbutton,'Callback',@obj.irf_background_guess_callback);
            set(obj.g_factor_guess_pushbutton,'Callback',@obj.g_factor_guess_callback);
            set(obj.tvb_define_pushbutton,'Callback',@obj.tvb_define_callback);
            set(obj.t0_guess_pushbutton,'Callback',@obj.t0_guess_callback)
            
            obj.update_controls();
            
        end
        
        function data_update(obj)
            for i=1:length(obj.lh)
                delete(obj.lh{i});
            end
            obj.lh = {};
            obj.lh{end+1} = addlistener(obj.data_series,'binning','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'downsampling','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'thresh_min','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'gate_max','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'t_min','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'t_max','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'t_irf_min','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'t_irf_max','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'irf_background','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'background_type','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'background_value','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'g_factor','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'afterpulsing_correction','PostSet',@obj.controls_updated);
            obj.lh{end+1} = addlistener(obj.data_series,'t0','PostSet',@obj.controls_updated);
                      
            obj.update_controls();
        end
        
        function masking_callback(obj,src,~)
            switch src
                case obj.t_min_edit
                    obj.data_series.t_min = str2double(get(obj.t_min_edit,'String'));
                case obj.t_max_edit
                    obj.data_series.t_max = str2double(get(obj.t_max_edit,'String'));
                case obj.t_irf_min_edit
                    obj.data_series.t_irf_min = str2double(get(obj.t_irf_min_edit,'String'));
                  case obj.t_irf_max_edit
                    obj.data_series.t_irf_max = str2double(get(obj.t_irf_max_edit,'String'));
                case obj.binning_popupmenu
                    obj.data_series.binning = get(obj.binning_popupmenu,'Value') - 1;
                case obj.downsampling_popupmenu
                    obj.data_series.downsampling = 2^( get(obj.downsampling_popupmenu,'Value') - 1 );
                case obj.thresh_min_edit
                    obj.data_series.thresh_min = str2double(get(obj.thresh_min_edit,'String'));
                case obj.gate_max_edit
                    obj.data_series.gate_max = str2double(get(obj.gate_max_edit,'String'));
                case obj.irf_background_edit
                    obj.data_series.irf_background = str2num(get(obj.irf_background_edit,'String'));
                case obj.background_value_edit
                    obj.data_series.background_value = str2double(get(obj.background_value_edit,'String'));
                case obj.background_type_popupmenu
                    obj.data_series.background_type = get(obj.background_type_popupmenu,'Value') - 1;    
                case obj.g_factor_edit
                    obj.data_series.g_factor = str2double(get(obj.g_factor_edit,'String'));
                case obj.afterpulsing_correction_checkbox
                    obj.data_series.afterpulsing_correction = get(obj.afterpulsing_correction_checkbox,'Value');
                case obj.t0_edit 
                    obj.data_series.t0 = str2double(get(obj.t0_edit,'String'));
            end
        end
        
        function irf_background_guess_callback(obj,~,~)
            obj.data_series.estimate_irf_background();
        end
        
        function t0_guess_callback(obj,~,~)
            %{
            mask = obj.roi_controller.roi_mask;
            dataset = obj.data_series_list.selected;
            t = obj.data_series.tr_t;
            
            data = obj.data_series.get_roi(mask,dataset); 
            fitted = obj.fit_controller.fitted_decay(t,mask,dataset);
            %}


            
            function chi2=f(t0)
                
                obj.data_series.t0 = t0;
                                
                obj.fit_controller.fit(true);
                while obj.fit_controller.has_fit == 0
                    pause(0.001);
                end

                %%% Get the fit results
                fit_result = obj.fit_controller.fit_result();
                
                chi2 = nanmean(fit_result.images{1}.chi2);
                
                return 
                
            end
            
            opt = optimset('PlotFcns',{@optimplotfval});
            t0_min = fminsearch(@f,obj.data_series.t0,opt);
            
            obj.data_series.t0 = t0_min;
            
            
            
        end
        
        function tvb_define_callback(obj,~,~)
            roi_mask = obj.roi_controller.roi_mask;
            dataset = obj.data_series_list.selected;
            obj.data_series.define_tvb_profile(roi_mask,dataset);
        end
        
        function g_factor_guess_callback(obj,~,~)
            obj.data_series.estimate_g_factor();
        end
        
        function controls_updated(obj,~,~)
            obj.update_controls();
        end
        
        function irf_plot_clicked(obj,src,evt)
            h = obj.irf_display_axes;
        end
        
        function update_background_plot(obj)
            h = obj.background_axes;
            d = obj.data_series;
            
            if d.init && d.background_type == 2
                imagesc(d.background_image,'Parent',h);
                colorbar('peer',h);
                colormap(h,'gray');
                daspect(h,[1 1 1]);
                set(h,'XTick',[]);
                set(h,'YTick',[]);
                set(obj.background_container,'Visible','on');
            else
                set(obj.background_container,'Visible','off');
                %set(h,'Visible','off')
            end
        end
        
        
        function update_controls(obj)

            if ~isempty(obj.binning_popupmenu)
                
                value = obj.data_series.binning;
                value = value + 1;
                set(obj.binning_popupmenu,'Value', value );
                
                value = obj.data_series.downsampling;
                value = log2(value) + 1;
                set(obj.downsampling_popupmenu,'Value', value );

                str = num2str(obj.data_series.thresh_min,'%2.4g');
                set(obj.thresh_min_edit,'String',str);

                str = num2str(obj.data_series.gate_max,'%2.4g');
                set(obj.gate_max_edit,'String',str);

                str = num2str(obj.data_series.t_min,'%2.4g');
                set(obj.t_min_edit,'String',str);

                str = num2str(obj.data_series.t_max,'%2.4g');
                set(obj.t_max_edit,'String',str);

                str = num2str(obj.data_series.t_irf_min,'%2.4g');
                set(obj.t_irf_min_edit,'String',str);

                str = num2str(obj.data_series.t_irf_max,'%2.4g');
                set(obj.t_irf_max_edit,'String',str);
                
                str = num2str(obj.data_series.irf_background,'%2.4g ');
                set(obj.irf_background_edit,'String',str);
                
                str = num2str(obj.data_series.g_factor,'%2.4g');
                set(obj.g_factor_edit,'String',str);
                
                value = obj.data_series.afterpulsing_correction;
                set(obj.afterpulsing_correction_checkbox,'Value',value);

                value = obj.data_series.background_type + 1;
                set(obj.background_type_popupmenu,'Value', value );
                
                str = num2str(obj.data_series.background_value,'%2.4g');
                set(obj.background_value_edit,'String',str);

                if obj.data_series.background_type == 1
                    set(obj.background_value_edit,'Enable','on');
                else
                    set(obj.background_value_edit,'Enable','off');
                end
                
                str = num2str(obj.data_series.t0,'%2.4g');
                set(obj.t0_edit,'String',str);
                
                obj.update_background_plot();
            end
            
        end
        
    end
    
end