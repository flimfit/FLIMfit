classdef abstract_plot_controller < flim_fit_observer

    properties
        plot_handle;
        handle_is_axes;
        param_popupmenu;
        data_series_list;
        contextmenu;
        window;
        param_list;
        
        selected;
        cur_param;

        
        ap_lh;
        
        raw_data;
    end
    
    methods(Abstract = true)
        
        draw_plot(obj,ax,param,evt);
        
    end
    
    methods

        
        function obj = abstract_plot_controller(handles,plot_handle,param_popupmenu,exports_data)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            obj.plot_handle = plot_handle;
            
            obj.handle_is_axes = strcmp(get(plot_handle,'type'),'axes');
            
            if nargin >= 3
                obj.param_popupmenu = param_popupmenu;
                set(obj.param_popupmenu,'Callback',@obj.param_select_update);
            else
                obj.param_popupmenu = [];
            end
                        
            if nargin < 4
                exports_data = false;
            end
                        
            assign_handles(obj,handles);

            addlistener(obj.data_series_list,'selection_updated',@obj.selection_updated);
            
            obj.selected = obj.data_series_list.selected;

            obj.contextmenu = uicontextmenu('Parent',obj.window);
            uimenu(obj.contextmenu,'Label','Save as...','Callback',...
                @(~,~,~) obj.save_as() );
            uimenu(obj.contextmenu,'Label','Save as Powerpoint...','Callback',...
                @(~,~,~) obj.save_as_ppt() );
            uimenu(obj.contextmenu,'Label','Export to Current Powerpoint','Callback',...
                @(~,~,~) obj.export_to_ppt() );
            if exports_data
                uimenu(obj.contextmenu,'Label','Export Data...','Callback',...
                @(~,~,~) obj.export_data() );
            end
            
            set(obj.plot_handle,'uicontextmenu',obj.contextmenu);
           
        end
        
        function save_as(obj)
            default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            [filename, pathname, ~] = uiputfile( ...
                        {'*.tiff', 'TIFF image (*.tiff)';...
                         '*.pdf','PDF document (*.pdf)';...
                         '*.png','PNG image (*.png)';...
                         '*.eps','EPS level 1 image (*.eps)';...
                         '*.fig','Matlab figure (*.fig)';...
                         '*.emf','Windows metafile (*.emf)';...
                         '*.*',  'All Files (*.*)'},...
                         'Select root file name',[default_path filesep]);

            if filename~=0
                
                [~,name,ext] = fileparts(filename);
                ext = ext(2:end);
                
                param_name = obj.fit_controller.fit_result.params{obj.cur_param};
                
                f = figure('Visible','off');
                if obj.handle_is_axes
                    ref = axes('Parent',f);
                else
                    ref = f;
                end
                
                obj.draw_plot(ref,obj.cur_param);
                if strcmp(ext,'emf')
                    print(f,'-dmeta',[pathname filesep name ' ' param_name '.' ext])
                else
                    savefig([pathname filesep name ' ' param_name],f,ext);
                end
                close(f);
            end
            
        end
        
        function save_as_ppt(obj)
            if ispref('GlobalAnalysisFrontEnd','LastFigureExportFolder')
                default_path = getpref('GlobalAnalysisFrontEnd','LastFigureExportFolder');
            else
                default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            end
            
            [filename, pathname, ~] = uiputfile( ...
                        {'*.ppt', 'Powerpoint (*.ppt)'},...
                         'Select root file name',[default_path filesep]);

            if ~isempty(filename)
                
                
                f = figure('Visible','off');
                if obj.handle_is_axes
                    ref = axes('Parent',f);
                else
                    ref = f;
                end
                             
                obj.draw_plot(ref,obj.cur_param);
                
                [~,name,ext] = fileparts(filename);
                file = [pathname filesep name ' ' obj.cur_param ext];
                if length(get(f,'children')) == 1 % if only one axis use pptfigure, gives better plots
                    ppt=saveppt2(file,'init');
                    pptfigure(f,'ppt',ppt);
                    saveppt2(file,'ppt',ppt,'close');
                else
                    saveppt2(file,'figure',f,'stretch',false);
                end
                setpref('GlobalAnalysisFrontEnd','LastFigureExportFolder',pathname);
            end
        end
        
        function export_to_ppt(obj)
            
            %scr =  get( 0, 'ScreenSize' );
            
            f = figure('Visible','on','units','pixels');%,'Position',scr);
            pos = get(f,'Position');
            pos(3:4) = [400,300];
            set(f,'Position',pos)
            
            if obj.handle_is_axes
                ref = axes('Parent',f);
            else
                ref = f;
            end
            
            obj.draw_plot(ref,obj.cur_param);
            if length(get(f,'children')) <= 2 % if only one axis use pptfigure, gives better plots
                saveppt2('current','currentslide','figure',f,'stretch',false,'driver','bitmap','scale',false);
            else
                saveppt2('current','figure',f,'stretch',false);
            end
            close(f);
        end
            
        
        function export_data(obj)
            if isempty(obj.raw_data)
                return
            end       
            
            
            default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            
            [filename, pathname, ~] = uiputfile( ...
                        {'*.csv', 'Comma Separated  Values (*.csv)'},...
                         'Select file name',[default_path filesep]);

            if filename ~= 0
               
                cell2csv([pathname filesep filename],obj.raw_data);
                
            end
        end
        
        function plot_fit_update(obj) 
        end
        
        function selection_updated(obj,~,~)
            obj.selected = obj.data_series_list.use_selected;
            obj.update_display();
        end
        
        
        function update_param_menu(obj,~,~)
            if obj.fit_controller.has_fit
                obj.param_list = obj.fit_controller.fit_result.fit_param_list();
                new_list = ['-',obj.param_list];
                for i=1:length(obj.param_popupmenu) 
                    old_list = get(obj.param_popupmenu(i),'String')';
                    
                    changed = length(old_list)~=length(new_list) || ...
                        any(~cellfun(@strcmp,old_list,new_list));

                    if changed
                        set(obj.param_popupmenu(i),'String',new_list);

                        if get(obj.param_popupmenu(i),'Value') > length(obj.param_list)
                            set(obj.param_popupmenu(i),'Value',1);
                        end

                        obj.param_select_update();    
                    end          
                end
            end
            
        end
        
        function param_select_update(obj,src,evt)
            % Get parameters from potentially multiple popupmenus
            val = get(obj.param_popupmenu,'Value');
            if iscell(val)
                val = cell2mat(val);
            end
            idx = val-1;
            obj.cur_param = idx;
            
            obj.update_display();
        end
        
        function lims_update(obj,src,evt)
            obj.update_display();
        end
        
        function fit_update(obj)
            obj.update_param_menu();
            obj.plot_fit_update();
            obj.update_display();
            obj.ap_lh = addlistener(obj.fit_controller.fit_result,'cur_lims','PostSet',@obj.lims_update);
        end
        
        function fit_display_update(obj)
            obj.update_display();
        end
        
        function update_display(obj)
            obj.draw_plot(obj.plot_handle,obj.cur_param);
        end
        
        function mapped_data = apply_colourmap(obj,data,param,lims)
            
            cscale = obj.colourscale(param);
            
            m=2^8;
            data = data - lims(1);
            data = data / (lims(2) - lims(1));
            data(data > 1) = 1;
            data(data < 0) = 0;
            data = data * m + 1;
            data(isnan(data)) = 0;
            data = int32(data);
            cmap = cscale(m);
            cmap = [ [1,1,1]; cmap];
            
            mapped_data = ind2rgb(data,cmap);
            
        end
        
        function cscale = colourscale(obj,param)
            
            param_name = obj.fit_controller.fit_result.params{param};
            invert = obj.fit_controller.invert_colormap;
            
            if strcmp(param_name,'I0') || strcmp(param_name,'I')
                cscale = @gray;
            elseif invert && (~isempty(strfind(param_name,'tau')) || ~isempty(strfind(param_name,'theta')))
                cscale = @inv_jet;
            else
                cscale = @jet;
            end
            
        end
        
        function im_data = plot_figure(obj,h,hc,dataset,param,merge,text)

            if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
                return
            end
            
            f = obj.fit_controller;

            intensity = f.get_intensity_image(dataset);
            im_data = f.get_image(dataset,param);

            
            cscale = obj.colourscale(param);

            lims = f.get_cur_lims(param);
            I_lims = f.get_cur_intensity_lims;
            if ~merge
                im=colorbar_flush(h,hc,im_data,isnan(intensity),lims,cscale,text);
            else
                im=colorbar_flush(h,hc,im_data,[],lims,cscale,text,intensity,I_lims);
            end
            

            if get(h,'Parent')==obj.plot_handle
                set(im,'uicontextmenu',obj.contextmenu);
            end
            
        end
       
    end
    
end