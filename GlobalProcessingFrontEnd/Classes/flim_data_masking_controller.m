classdef flim_data_masking_controller < control_binder & flim_data_series_observer
    
    properties
        roi_controller;
        data_series_list;
        fit_controller;
        
        irf_lower_ann = [];
        irf_upper_ann = [];
        
        lh = {};
    end
       
    methods 
        function obj = flim_data_masking_controller(handles)
        
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@control_binder(handles.data_series_controller.data_series);
            
            assign_handles(obj,handles);
            
            obj.bind_control(handles,'binning','popupmenu');
            obj.bind_control(handles,'thresh_min','edit');
            obj.bind_control(handles,'gate_max','edit');
            obj.bind_control(handles,'t_min','edit');
            obj.bind_control(handles,'t_max','edit');
            obj.bind_control(handles,'t_irf_min','edit');
            obj.bind_control(handles,'t_irf_max','edit');
            obj.bind_control(handles,'irf_background','edit');
            obj.bind_control(handles,'g_factor','edit');
            obj.bind_control(handles,'afterpulsing_correction','popupmenu');
            obj.bind_control(handles,'background_value','edit');
            obj.bind_control(handles,'background_type','popupmenu');
            obj.bind_control(handles,'ref_lifetime','edit');
            obj.bind_control(handles,'rep_rate','edit');
            obj.bind_control(handles,'irf_type','popupmenu');
            obj.bind_control(handles,'t0','edit');
            obj.bind_control(handles,'counts_per_photon','edit')
                       
            obj.update_controls();
            
        end
        
        function data_set(obj)
            obj.set_bound_data_source(obj.data_series);
        end
        
        function data_update(obj)
        end
        
        
        
        function irf_background_guess_callback(obj,~,~)
            obj.data_series.estimate_irf_background();
        end
        
        function t0_guess_callback(obj,~,~)
            
            function chi2=f(t0)
                
                obj.data_series.t0 = t0;
                                
                obj.fit_controller.fit(true);
                while obj.fit_controller.has_fit == 0
                    pause(0.001);
                end

                %%% Get the fit results
                fit_result = obj.fit_controller.fit_result();
                
                chi2 = nanmean(fit_result.images{1}.chi2);
                
                if fit_result.ierr < 0
                    chi2 = chi2 + 1000;
                end
                
                return 
                
            end
            
            opt = optimset('PlotFcns',{@optimplotfval}); %,'TolX',0.05);
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
            
            if isfield(obj.controls,'background_value_edit')
                if obj.data_series.background_type == 1
                    set(obj.controls.background_value_edit,'Enable','on');
                else
                    set(obj.controls.background_value_edit,'Enable','off');
                end
            end
            
            if isfield(obj.controls,'ref_lifetime_edit')
                if obj.data_series.irf_type == 0
                    set(obj.controls.ref_lifetime_edit,'Enable','off');
                else
                   set(obj.controls.ref_lifetime_edit,'Enable','on');
                end
            end
            
        end
        
    end
    
end