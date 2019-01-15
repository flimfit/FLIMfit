classdef help_menu_controller < handle
    
    
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
        data_series_controller;
        model_controller;
        temp_model_name;
    end
    
    methods(Access=private)
        function open_browser(~, url_str)
            % cut down web function to open a web browser without HelpUtils
            
            stat = -1; %default
            
            if ismac
                 % We can't detect system errors on the Mac, so the warning options are unnecessary.
                unix(['open ' url_str]);
                stat = 0;
       
            elseif isunix
                
                errordlg('Sorry! - not currently available for Linux/Unix', 'Browser Error')
            
            elseif ispc
                stat = dos(['cmd.exe /c rundll32 url.dll,FileProtocolHandler "' url_str '"']);
            end
            
            if stat ~= 0
                errordlg(horzcat('Failed to open browser! Please direct a browser to ', url_str ),'Browser Error');
                
            end
                        
        end 
    end
    
    methods
        
        function obj = help_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
        end
        
        function menu_help_about(obj, ~, ~)
            ver = obj.data_series_controller.version;
            HelpAbout('Property', ver); 
        end

        function menu_help_tracker(obj, ~, ~)
            
            obj.open_browser('https://github.com/imperial-photonics/FLIMfit/issues');
            
        end

        function menu_help_bugs(obj, ~, ~)
            obj.open_browser('https://github.com/imperial-photonics/FLIMfit/issues/new'); 
        end
        
        function menu_help_check_version(~, ~, ~)
            check_version();
        end
        
        function menu_help_load(obj, ~, ~)
            obj.model_controller.new_model();
            if ~isempty(obj.temp_model_name)
                obj.model_controller.load(obj.temp_model_name);
            end
        end
        
        function menu_help_unload(obj, ~, ~)
            obj.temp_model_name = tempname;
            obj.model_controller.save(obj.temp_model_name);
            obj.model_controller.clear_model();
            clear FLIMFitMex
        end
        
    end
    
end
