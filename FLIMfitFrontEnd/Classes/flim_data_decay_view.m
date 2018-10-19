classdef flim_data_decay_view < handle & abstract_display_controller ...
                                       & flim_data_series_observer
    
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
       roi_controller;
       fitting_params_controller;
       fit_controller;

       decay_panel;
       
       highlight_display_mode_popupmenu;
       highlight_decay_mode_popupmenu;
       decay_pos_text; % Text to display currently selected pixel location
       
       ylim_highlight;
       ylim_residual;
       xlim_highlight;
       xlim_residual;
       
       lh;
       
       
       data = [];
       fit = [];
       residual = [];
       bg_line = [];
       irf = [];
       t = [];
       t_irf = [];
       
       fit_binned = false;
       n_sum = 0;
       data_type = '';
       
    end

    methods

        function obj = flim_data_decay_view(handles)

            obj = obj@flim_data_series_observer(handles.data_series_controller);
            obj = obj@abstract_display_controller(handles,handles.decay_panel,true);
                            
            assign_handles(obj,handles)

            addlistener(obj.roi_controller,'roi_updated',@(~,~) EC(@obj.update_display));
            addlistener(obj.fit_controller,'fit_updated',@(~,~) EC(@obj.update_display));
            set(obj.highlight_display_mode_popupmenu,'Callback',@(~,~) EC(@obj.update_display));
            set(obj.highlight_decay_mode_popupmenu,'Callback',@(~,~) EC(@obj.update_display));
            
            obj.register_tab_function('Decay');
            
            obj.update_display();
        end
        
        function data_set(obj)
            delete(obj.lh);
            obj.lh = addlistener(obj.data_series,'masking_updated',@(~,~) EC(@obj.data_update_evt));
        end
                
        function data_update(obj)
           %obj.update_display(); 
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
        
        function update_data(obj)
            
            decay_mode = get(obj.highlight_decay_mode_popupmenu,'Value');

            if isempty(decay_mode)
                decay_mode = 1;
            end

            decay_modes = get(obj.highlight_decay_mode_popupmenu,'String');
            obj.data_type = decay_modes{decay_mode};
            
            obj.data = [];
            obj.fit = [];
            obj.residual = [];
            obj.bg_line = [];
            obj.irf = [];
            obj.t = [];
            obj.t_irf = [];
            
            if ~isempty(obj.data_series) && obj.data_series.init
                          
                d = obj.data_series;                        
                mask = obj.roi_controller.roi_mask;

                if ~isempty(obj.data_series_list)
                    dataset = obj.data_series_list.selected;
                else
                    dataset = 1;
                end

                if isempty(mask) || dataset == 0
                    obj.data = [];
                    obj.residual = [];
                    obj.irf = [];
                    obj.bg_line = [];
                    obj.fit = [];
                    return
                end

                obj.t = d.tr_t(:);
                obj.t_irf = obj.data_series.irf.tr_t_irf(:);

                switch decay_mode
                    case 1
                        [obj.data, obj.irf] = obj.data_series.get_roi(mask,dataset);
                    case 2
                        obj.data = obj.data_series.irf.irf;
                        obj.t = d.irf.t_irf;
                        obj.bg_line = ones(size(obj.t))*d.irf.irf_background;
                    case 3
                        obj.data = obj.data_series.tr_tvb_profile;
                    case 4
                        [obj.data,obj.irf] = obj.data_series.get_magic_angle_roi(mask,dataset);
                    case 5
                        obj.data = obj.data_series.get_anisotropy_roi(mask,dataset);
                    case 6
                        obj.data = obj.data_series.get_g_factor_roi(mask,dataset);
                        obj.bg_line = ones(size(obj.t))*d.g_factor;
                end

                if length(size(obj.data)) > 2
                    obj.n_sum = size(obj.data,1) * size(obj.data,2);
                    obj.data = squeeze(nanmean(obj.data,3));
                else
                    obj.n_sum = 1;
                end
                     
                if ~isempty(obj.fit_controller) && obj.fit_controller.has_fit
                    
                    obj.fit_binned = obj.fit_controller.fit_result.binned;
                    
                    switch decay_mode
                        case 1
                            obj.fit = obj.fit_controller.fitted_decay(obj.t,mask,obj.data_series_list.selected);
                        case 4
                            obj.fit = obj.fit_controller.fitted_magic_angle(obj.t,mask,obj.data_series_list.selected);
                        case 5
                            obj.fit = obj.fit_controller.fitted_anisotropy(obj.t,mask,obj.data_series_list.selected);
                    end

                    if ~isempty(obj.fit) && all(size(obj.fit)==size(obj.data))
                        dataz = obj.data;
                        dataz(dataz<0) = 0;
                        obj.residual = (obj.fit-dataz)./sqrt(dataz);
                    end
                end
            end
            
            
        end
        
        function [ha,ra] = setup_axes(obj,f)
           
            children = get(f,'Children');
            if ~isempty(children)
                for i=1:length(children)
                    delete(children(i))
                end
            end
            
            set(f,'Units','Normalized');
            ha = axes('OuterPosition',[0 0.3 1 0.7],'Box','off','Parent',f);
            ra = axes('OuterPosition',[0 0 1 0.32],'XTickLabel',[],'Parent',f);
      
        end
        
        function draw_plot(obj,f)
            
            export_plot = (nargin == 2);
            if ~export_plot
                f = obj.plot_handle;
            end
            
            try%#ok
            set(f,'BackgroundColor','w');
            end
            try%#ok
            set(f,'Color','w');
            end
            
            children = get(f,'Children');
            
            if length(children) == 2
                ra = children(1);
                ha = children(2);
            else
                [ha,ra] = obj.setup_axes(f);
            end
            
            obj.update_data();
            
            hold(ha,'off');
            
            first_call = isempty(obj.ylim_highlight) && ~export_plot;
                
            warning('off','MATLAB:Axes:NegativeDataInLogAxis');
            
            display_mode = get(obj.highlight_display_mode_popupmenu,'Value');            

            if isempty(display_mode)
                display_mode = 1;
            end

            switch display_mode
                case 2
                    plot_fcn = @semilogy;
                otherwise                             
                    plot_fcn = @plot;
            end
                     
            cla(ha);
            cla(ra);
            
            if ~isempty(obj.data)
                
                sum_t = sum(obj.data);
                avg_t = mean(obj.data);
                
                txt = [obj.roi_controller.click_pos_txt ' Total Intensity = ' num2str(sum_t)];
                txt = [txt ', Average / Timepoint = ' num2str(avg_t)];
                set(obj.decay_pos_text,'String',txt);
                plot_fcn(ha,obj.t,obj.data,'o');
                hold(ha,'on');
            end

            if ~isempty(obj.bg_line)
                plot_fcn(ha,obj.t,obj.bg_line,'r--');
                hold(ha,'on');
            end

            if ~isempty(obj.irf)
                % Plot IRF
                scale = double(max(obj.data(:)))/max(obj.irf(:));
                plot_fcn(ha,obj.t_irf,obj.irf*scale,'r-.');
                hold(ha,'on');
            end
            
            set(ra,'OuterPosition',[0 0 1 0.32]);
                           
            if ~isempty(obj.fit)
                set(ra,'Visible','on');
                set(ha,'OuterPosition',[0 0.3 1 0.7]);
                if obj.fit_binned
                    plot_style = 'b--';
                else
                    plot_style = 'b';
                end  
                            
                plot_fcn(ha,obj.t,obj.fit,plot_style);
                
                cla(ra);
                plot(ra,obj.t,obj.residual);
                hold(ra,'on');
                plot(ra,[-1e7 1e7],[0 0],'-k');
                
                              
                set(ra, ...
                  'Box'         , 'off'      , ...
                  'TickDir'     , 'out'      , ...
                  'TickLength'  , [.02 .02]  , ...
                  'YGrid'       , 'off'      , ...
                  'LineWidth'   , 1          , ...
                  'XColor'      , 'w');
              
                m = abs(obj.residual);
                m = m(isfinite(m));
                m = max(m(:));
                if ~isempty(m) && m>0
                    ylim(ra,[-m-1e-3 m+1e-3]);
                end
                set(obj.plot_handle,'uicontextmenu',obj.contextmenu);
                
            else
                cla(ra);
                set(ra,'Visible','off');
                set(ha,'OuterPosition',[0 0 1 1]);
            end

            % Set Y limits
            if ~isempty(obj.data)
               if display_mode == 1
                   low = 0;
               else
                   low = 0.9*min(obj.data(:));
               end
               high = max(obj.data(:))*1.1;

               if (isempty(low) || low == high )
                   low = 0;
               end

               if (isempty(high) || high == 0)
                   high = 1;
               end

               obj.ylim_highlight = [low high];

            else
                obj.ylim_highlight = [max(obj.irf(:))/100 max(obj.irf(:))];
            end

            try %#ok               
                ylim(ha,obj.ylim_highlight);
                ylim(ra,obj.ylim_residual);
            end
            
            % Set X limits
            try
                xmax = max([max(obj.t) max(obj.t_irf)]);
                obj.xlim_highlight = [0 xmax];
                obj.xlim_residual = [0 xmax];
            catch %#ok
                obj.xlim_highlight = [0 12.5e3];
                obj.xlim_residual = [0 12.5e3];
            end
            try %#ok                    
                xlim(ha,obj.xlim_highlight);
                xlim(ra,obj.xlim_residual);
            end

            if ~export_plot
                set(ha,'uicontextmenu',obj.contextmenu);
                set(ra,'uicontextmenu',obj.contextmenu);
            end

            set(ha, ...
                  'Box'         , 'off'      , ...
                  'TickDir'     , 'out'      , ...
                  'TickLength'  , [.02 .02]  , ...
                  'YGrid'       , 'off'      , ...
                  'LineWidth'   , 1          );

                 
            xlabel(ha,'Time (ps)');
            ylabel(ha,obj.data_type);
            ylabel(ra,'Norm Residual');
           
              
            hold(ha,'off');
            hold(ra,'off');
                        
        end
        
        function auto_export = export(obj,file)

            auto_export = false;
            obj.update_data();

            [path, name, ext] = fileparts(file);
           
           
            if ~isempty(obj.data)
                
                 % Collate Data
                export_data = [obj.t obj.data obj.fit obj.residual];
                file_name = [path name ext];
           
                f=fopen(file_name,'w');
                fprintf(f,'t');
                for i=1:size(obj.data,2)
                   fprintf(f,[obj.data_type '_ch' num2str(i-1)]); 
                end
                if ~isempty(obj.fit)
                    fprintf(f,',Fit,Normalised Residual');
                end
                fprintf(f,'\r\n');
                fclose(f);

                dlmwrite(file_name,export_data,'-append','delimiter',',');
            end

            if length(obj.irf) > 3
                
                irf_data = [];
                
                % fix to handle https://github.com/openmicroscopy/Imperial-FLIMfit/issues/149
                % NB fixing the symptom rather than the cause 
                s1 = size(obj.irf);
                s2 = size(obj.t_irf);
                if s1 == s2
                    irf_data = [obj.t_irf obj.irf];
                else
                    if s1 == flip(s2)
                        irf_data = [obj.t_irf obj.irf'];
                    end
                end
                if ~isempty(irf_data)
                    irf_file_name = [path name '_irf' ext];
                    f=fopen(irf_file_name,'w');
                    fprintf(f,'t (ps),IRF\r\n');
                    fclose(f);
                    dlmwrite(irf_file_name,irf_data,'-append','delimiter',',');
                 end
            end
        end
        
    end
    
end