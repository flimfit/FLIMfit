classdef flim_data_decay_view < handle & flim_data_series_observer & flim_fit_observer
   
    properties
       roi_controller;
       data_series_list;
       fitting_params_controller;

       highlight_axes;
       residuals_axes;
       highlight_display_mode_popupmenu;
       highlight_decay_mode_popupmenu;
       fit;
       
       ylim_highlight;
       ylim_residual;
       xlim_highlight;
       xlim_residual;
       
       lh;
    end

    methods

        function obj = flim_data_decay_view(handles)

            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@flim_fit_observer(handles.fit_controller);
                            
            assign_handles(obj,handles)

            if ~isempty(obj.data_series_list)
                addlistener(obj.data_series_list,'selection_updated',@obj.roi_update);
            end
            addlistener(obj.roi_controller,'roi_updated',@obj.roi_update);
            set(obj.highlight_display_mode_popupmenu,'Callback',@obj.display_mode_update);
            set(obj.highlight_decay_mode_popupmenu,'Callback',@obj.display_mode_update);
            
            obj.update_display();
        end
        
        function data_set(obj)
            delete(obj.lh);
            obj.lh = addlistener(obj.data_series,'masking_updated',@obj.data_update_evt);
        end
        
        function display_mode_update(obj,~,~)
            obj.update_display();
        end
        
        function roi_update(obj,~,~)
            obj.update_display();
        end
        
        function data_update(obj)
           %obj.update_display(); 
        end
        
        function fit_update(obj)
           obj.update_display(); 
        end
        
        function lims = get_axis_lims(obj,idx)
            
            lims = cell(2,1);
            if idx == 1
                lims{1} = obj.xlim_highlight;
                lims{2} = obj.ylim_highlight;
            else
                lims{1} = obj.xlim_residual;
                lims{2} = obj.ylim_residual;
            end
                
            return;
        end
        
        function update_display(obj,file,export_all)
            
            first_call = isempty(obj.ylim_highlight);
                
            warning('off','MATLAB:Axes:NegativeDataInLogAxis');
            
            if obj.data_series.init
                
                display_mode = get(obj.highlight_display_mode_popupmenu,'Value');            
                decay_mode = get(obj.highlight_decay_mode_popupmenu,'Value');

                if isempty(decay_mode)
                    decay_mode = 1;
                end
                if isempty(display_mode)
                    display_mode = 1;
                end
                
                if nargin < 2
                    file = [];
                end

                data = [];
                residual = [];

                d = obj.data_series;                        
                mask = obj.roi_controller.roi_mask;

                if ~isempty(obj.data_series_list)
                    datasets = obj.data_series_list.selected;
                else
                    datasets = 1;
                end
                export_all = false;
 

                switch display_mode
                    case 2
                        plot_fcn = @semilogy;
                    otherwise                             
                        plot_fcn = @plot;
                end

                if ~isempty(mask)

                    for dataset = datasets
                        data = [];
                        bg_line = [];
                        irf = [];
                        t_decay = d.tr_t;
                        t_irf = obj.data_series.tr_t_irf;
                        % Plot decay data
                        switch decay_mode
                            case 1
                                [data, irf] = obj.data_series.get_roi(mask,dataset);
                                %irf = obj.data_series.tr_irf;
                            case 2
                                data = obj.data_series.irf;
                                t_decay = d.t_irf;
                                bg_line = ones(size(t_decay))*d.irf_background;
                            case 3
                                data = obj.data_series.tr_tvb_profile;
                            case 4
                                [data,irf] = obj.data_series.get_magic_angle_roi(mask,dataset);
                            case 5
                                data = obj.data_series.get_anisotropy_roi(mask,dataset);
                            case 6
                                data = obj.data_series.get_g_factor_roi(mask,dataset);
                                bg_line = ones(size(t_decay))*d.g_factor;
                        end

                        if length(size(data)) > 2
                            n_sum = size(data,1) * size(data,2);
                            data = squeeze(nanmean(data,3));
                        else
                            n_sum = 1;
                        end
                     
                        cla(obj.highlight_axes);

                        if ~isempty(data)
                            plot_fcn(obj.highlight_axes,t_decay,data,'o');
                            hold(obj.highlight_axes,'on');
                        end

                        if ~isempty(bg_line)
                            plot_fcn(obj.highlight_axes,t_decay,bg_line,'r--');
                        end

                        if ~isempty(irf)
                            % Plot IRF
                            scale = double(max(data(:)))/max(irf(:));
                            plot_fcn(obj.highlight_axes,t_irf,irf*scale,'--');
                        end

                       if ~isempty(file)
                            [path name ext] = fileparts(file);
                            if export_all
                                wfile = [path filesep d.names{dataset} '_' name ext];
                                wifile = [path filesep d.names{dataset} '_' name '_irf' ext];
                            else
                                wfile = [path filesep name ext];
                                wifile = [path filesep name '_irf' ext];
                            end
                            dlmwrite(wfile,[t_decay' data],'\t');
                            dlmwrite(wifile,[t_irf irf],'\t');
                        end


                        if ~isempty(obj.fit_controller) && obj.fit_controller.has_fit %&& decay_mode == 1                

                            %Plot fit
                            if true || strcmp(d.mode,'TCSPC')
                                t = d.tr_t;
                            else
                                dt = d.t_irf(2)-d.t_irf(1);
                                t = 0:dt:max(d.tr_t);
                            end
                                                        
                            if obj.fit_controller.fit_result.binned == true
                                plot_style = 'r--';
                            else
                                plot_style = 'r';
                            end  
                            %t = min(d.tr_t):20:max(d.tr_t);

                            fitted = [];
                            switch decay_mode
                                case 1
                                    fitted = obj.fit_controller.fitted_decay(t,mask,obj.data_series_list.selected);
                                    fitted_res = obj.fit_controller.fitted_decay(d.tr_t,mask,obj.data_series_list.selected);
                                case 4
                                    fitted = obj.fit_controller.fitted_magic_angle(t,mask,obj.data_series_list.selected);
                                    fitted_res = obj.fit_controller.fitted_magic_angle(d.tr_t,mask,obj.data_series_list.selected);
                                case 5
                                    fitted = obj.fit_controller.fitted_anisotropy(t,mask,obj.data_series_list.selected);
                                    fitted_res = obj.fit_controller.fitted_anisotropy(d.tr_t,mask,obj.data_series_list.selected);

                            end

                            if ~isempty(fitted) 
                                plot_fcn(obj.highlight_axes,t,fitted,plot_style);

                                if decay_mode == 1 || decay_mode == 4 || decay_mode == 5
                                    % Calculate & plot normalised residuals
                                    %fitted_res = obj.fit_controller.fitted_decay(d.tr_t,mask,obj.data_series_list.selected);                    
                                    data(data<0) = 0;

                                    residual = (fitted_res-data)./sqrt(data);
                                    plot(obj.residuals_axes,d.tr_t,residual);

                                    m = nanmax(abs(residual(:)));
                                    if m~=0 && ~isnan(m)
                                        ylim(obj.residuals_axes,[-m-1e-3 m+1e-3]);
                                    end
                                else
                                    residual = [];
                                end

                                if ~isempty(file)
                                    [path name ext] = fileparts(file);
                                    if export_all
                                        wfile = [path filesep d.names{dataset} '_' name '_fit' ext];
                                    else
                                        wfile = [path filesep name '_fit' ext];
                                    end
                                    dlmwrite(wfile,[t' fitted residual],'\t');
                                end


                            end
                        else
                            if ~isempty(obj.residuals_axes)
                                cla(obj.residuals_axes);
                            end
                        end
                    end
                end

                if ~isempty(obj.residuals_axes)
                    grid(obj.residuals_axes,'on');             
                    ylabel(obj.residuals_axes,'Normalised Residuals');
                    xlabel(obj.residuals_axes,'Time (ps)')
                end
                
                grid(obj.highlight_axes,'on');
                ylabel(obj.highlight_axes,'ROI Intensity');
                xlabel(obj.highlight_axes,'Time (ps)')
                
                
                % Set X limits
                try
                    xmax = max([max(obj.data_series.tr_t) max(obj.data_series.tr_t_irf)]);
                    obj.xlim_highlight = [0 xmax];
                    obj.xlim_residual = [0 xmax];
                catch %#ok
                    obj.xlim_highlight = [0 12.5e3];
                    obj.xlim_residual = [0 12.5e3];
                end

                % Set Y limits
                %if decay_mode == 1
                    if ~all(data==1)
                       if display_mode == 1
                           low = 0;
                       else
                           low = 0.9*min(data(:));
                       end
                       high = max(data(:))*1.1;

                       if (isempty(low) || low == high )
                           low = 0;
                       end

                       if (isempty(high) || high == 0)
                           high = 1;
                       end

                       obj.ylim_highlight = [low high];

                    else
                        obj.ylim_highlight = [max(d.tr_irf(:))/100 max(d.tr_irf(:))];

                    end
                    
                    %obj.ylim_residual = [nanmin(residual),nanmax(residual)];
                    
                %end
                
                
                try                    
                    xlim(obj.highlight_axes,obj.xlim_highlight);
                    xlim(obj.residuals_axes,obj.xlim_residual);
                end
                try                    
                    ylim(obj.highlight_axes,obj.ylim_highlight);
                    ylim(obj.residuals_axes,obj.ylim_residual);
                end
                
                if first_call
                    dragzoom([obj.highlight_axes obj.residuals_axes],'on',@obj.get_axis_lims)
                end

                hold(obj.highlight_axes,'off');
            end
                        
        end
        
        
    end
    
end