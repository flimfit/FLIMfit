classdef abstract_display_controller < handle
    
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
        plot_handle;
        handle_is_axes;
        data_series_list;
        contextmenu;
        window;
        display_tabpanel;
        selected;
        
        registered_tab;
        raw_data;
    end
    
    methods(Abstract = true)
        
        draw_plot(obj,ax);
        
    end
    
    methods

        
        function obj = abstract_display_controller(handles,plot_handle,exports_data)
                       
            obj.plot_handle = plot_handle;
            obj.handle_is_axes = strcmp(get(plot_handle,'type'),'axes');
                        
            if nargin < 3
                exports_data = false;
            end
                        
            assign_handles(obj,handles);

            addlistener(obj.data_series_list,'selection_updated',@(~,~) EC(@obj.selection_updated));
            
            obj.selected = obj.data_series_list.selected;

            obj.contextmenu = uicontextmenu('Parent',obj.window);
            
            
            uimenu(obj.contextmenu,'Label','Save as...','Callback',...
                @(~,~,~) obj.save_as() );
            if strfind(computer, 'PCWIN') 
               uimenu(obj.contextmenu,'Label','Save as Powerpoint...','Callback',...
                    @(~,~,~) obj.save_as_ppt() );
                uimenu(obj.contextmenu,'Label','Export to Current Powerpoint','Callback',...
                    @(~,~,~) obj.export_to_ppt() );
            end
            if exports_data
                uimenu(obj.contextmenu,'Label','Export Data...','Callback',...
                @(~,~,~) obj.export_data() );
            end
           
            set(obj.plot_handle,'uicontextmenu',obj.contextmenu);
           
        end
        
        function auto_export = export(~,~)
            auto_export = true;
        end
        
        function save_as(obj)
            
            if strcmp(obj.registered_tab, 'Decay')
                param_name = 'Decay';
            else
                
                if  obj.fit_controller.has_fit == 0
                    param_name = [];
                else
                    param_name = obj.fit_controller.fit_result.params{obj.cur_param};
                end
            end
            
            if isempty(param_name)
                errordlg('Sorry! No image available.');
            else
                
                % should be done by overloading but for now use 'ifs'
                % in the interests of keeping the file_side stable
                if obj.fit_controller.data_series.loaded_from_OMERO
                    default_name = [''];
                    [filename, pathname, dataset, before_list] = obj.fit_controller.data_series.prompt_for_export('root filename', '','.tiff');
                     
                else
                    
                    default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
                    [filename, pathname, ~] = uiputfile( ...
                        {'*.tif', 'TIFF image (*.tif)';...
                        '*.pdf','PDF document (*.pdf)';...
                        '*.png','PNG image (*.png)';...
                        '*.eps','EPS image (*.eps)';...
                        '*.fig','Matlab figure (*.fig)'},...
                        'Select root file name',[default_path filesep]);
                end
                
                if filename~=0
                    
                    [~,name,ext] = fileparts(filename);
                    ext = ext(2:end);
                    
                    [f,ref] = obj.make_hidden_fig();
                    obj.draw_plot(ref);
                    
                    filename = [pathname name  param_name '.' ext];

                    switch ext
                        case 'fig'
                            savefig(f,filename); 
                        otherwise
                            export_fig(f, filename );
                    end
                    close(f);
                    
                    if obj.fit_controller.data_series.loaded_from_OMERO
                         obj.fit_controller.data_series.export_new_images(pathname,[name '.' ext],before_list, dataset);
                    end
                    
                    
                    
                end
            end
            
        end
        
        function save_as_ppt(obj)
            
            if strcmp(obj.registered_tab, 'Decay')
                param_name = 'Decay';
            else
                if  obj.fit_controller.has_fit == 0
                    param_name = [];
                else
                    param_name = obj.fit_controller.fit_result.params{obj.cur_param};
                end
            end
            
            if isempty(param_name)
                errordlg('Sorry! No image available.');
                return;
            end
            
            
            if ispref('GlobalAnalysisFrontEnd','LastFigureExportFolder')
                default_path = getpref('GlobalAnalysisFrontEnd','LastFigureExportFolder');
            else
                default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
            end
            
            [filename, pathname, ~] = uiputfile( ...
                        {'*.ppt', 'Powerpoint (*.ppt)'},...
                         'Select root file name',[default_path filesep]);

            if filename ~= 0
                
                [f,ref] = obj.make_hidden_fig([300, 400]);
                
                obj.draw_plot(ref);
                
                [~,name,ext] = fileparts(filename);
                file = [pathname filesep name ' ' param_name '.' ext];
                % pptfigure does not seem to have been updated to 2014b.
                % Comment out for now. 
                %if length(get(f,'children')) == 1 % if only one axis use pptfigure, gives better plots
                %    ppt=saveppt2(file,'init');
                %    pptfigure(f,'ppt',ppt);
                %    saveppt2(file,'ppt',ppt,'close');
                %else
                    saveppt2(file,'figure',f,'stretch',false);
                %end
                setpref('GlobalAnalysisFrontEnd','LastFigureExportFolder',pathname);
                
                close(f)
            end
        end
        
        function export_to_ppt(obj,varargin)
           
            [f,ref] = obj.make_hidden_fig([400,300]);
            
            obj.draw_plot(ref);
            if length(get(ref,'children')) <= 2 % if only one axis use pptfigure, gives better plots
                saveppt2('current','currentslide','figure',f,'stretch',false,'driver','bitmap','scale',false,varargin{:});
            else
                saveppt2('current','currentslide','figure',f,'stretch',false,varargin{:});
            end
            close(f);
        end
            
        
        function export_data(obj,filename)   
            
            if nargin < 2
            
                default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');

                [file, pathname, ~] = uiputfile( ...
                            {'*.csv', 'Comma Separated  Values (*.csv)'},...
                             'Select file name',[default_path filesep]);
                         
                if file ~= 0
                    filename = [pathname filesep file];
                else 
                    return
                end
                
            end
                 
            if obj.export(filename) % returns true if it wants us to autoexport
                cell2csv(filename,obj.raw_data);
            end
                
        end
        
        function plot_fit_update(obj) 
        end
        
        function selection_updated(obj)
            obj.selected = obj.data_series_list.selected;
            obj.update_display();
        end
        
        
        function update_display(obj)
            if obj.is_active_tab(obj.registered_tab)
                obj.draw_plot();
            end
        end
        
        function ret = is_active_tab(obj,tab)
            tabs = get(obj.display_tabpanel,'TabTitle');
            sel = get(obj.display_tabpanel,'Selection');
           
            ret = strcmp(tabs{sel},tab);
        end
        
        function register_tab_function(obj,tab)
            
            last_fcn = get(obj.display_tabpanel,'SelectionChangedFcn');
            
            function fcn(obj1,src)
                tabs = get(obj.display_tabpanel,'TabTitles');
           
                if strcmp(tabs{src.NewValue},tab);
                    obj.draw_plot();
                end
                last_fcn(obj1,src);
            end
        
            set(obj.display_tabpanel,'SelectionChangedFcn',@fcn);
            
            obj.registered_tab = tab;
            
        end
        
        function [f,ref] = make_hidden_fig(obj,sz)
            f = figure('Visible','on','units','pixels');
            pos = get(f,'Position');
            
            if nargin == 2
                pos(3:4) = sz;
                set(f,'Position',pos)
            end
          
            if obj.handle_is_axes
                ref = axes('Parent',f);
            else
                ref = f;
            end
        end
            
        
       
    end
    
end