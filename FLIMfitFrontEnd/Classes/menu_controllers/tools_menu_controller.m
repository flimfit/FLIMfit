classdef tools_menu_controller < handle
    
    
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
        data_masking_controller;
        data_series_list;
        omero_logon_manager
    end
    
    methods
        
        function obj = tools_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
        end
        
         
        function menu_tools_create_irf_shift_map(obj)
                        
            mask=obj.data_masking_controller.roi_controller.roi_mask;
            sel = obj.data_series_list.selected;
            t0_data = obj.data_series_controller.data_series.generate_t0_map(mask,sel);
            
            OMEROsave = false;
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series')                
                choice = questdlg('Do you want to export t0 shift data to the current OMERO server or save on disk?', ' ', ...
                                        'Omero' , ...
                                        'disk','Cancel','Cancel');  
                if strcmp( choice, 'Cancel'), return, end 
                if strcmp( choice, 'Omero')
                    [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
                    OMEROsave = true;
                end    
            end
            
            if ~OMEROsave
                [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',default_path);
            end                                                               
            if filename ~= 0
                serialise_object(t0_data,[pathname filename],'flim_data_series');
                if OMEROsave
                    add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                        dataset, ...
                        char('application/octet-stream'), ...
                        [pathname filename], ...
                        '', ...
                        'IC_PHOTONICS');
                end
            end
                        
        end
        
        function menu_tools_fit_gaussian_irf(obj)
            
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = sum(double(data),3);
            
            analytical = false;
            
            estimate_irf_interface(t,data,T,analytical,default_path);
            
        end

        function menu_tools_fit_analytical_irf(obj)
            
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = sum(double(data),3);
            
            analytical = true;
            
            estimate_irf_interface(t,data,T,analytical,default_path);
            
        end

        
        function menu_tools_create_tvb_intensity_map(obj)

            mask=obj.data_masking_controller.roi_controller.roi_mask;
            tvb_data = obj.data_series_controller.data_series.generate_tvb_I_map(mask,1);  
            
            OMEROsave = false;
            
            if isa(obj.data_series_controller.data_series,'OMERO_data_series')                
                choice = questdlg('Do you want to export t0 shift data to the current OMERO server or save to disk?', ' ', ...
                                        'Omero' , ...
                                        'disk','Cancel','Cancel');  
                if strcmp( choice, 'Cancel'), return, end; 
                if strcmp( choice, 'Omero')
                    [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
                    OMEROsave = true;
                end   
            end
            
            if ~OMEROsave
                [filename, pathname] = uiputfile({'*.xml', 'XML File (*.xml)'},'Select file name',default_path);
            end                                                                  
            if filename ~= 0
                serialise_object(tvb_data,[pathname filename],'flim_data_series');
                if OMEROsave
                    add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                        dataset, ...
                        char('application/octet-stream'), ...
                        [pathname filename], ...
                        '', ...
                        'IC_PHOTONICS');
                end
            end
        end
        
        function menu_tools_photon_stats(obj)
            d = obj.data_series_controller.data_series;
            
            % get data without smoothing
            d.compute_tr_data(false,true);
            
             data = d.cur_tr_data;
            [N,Z] = determine_photon_stats(data);
            
            d.counts_per_photon = N;
            d.background_value = d.background_value + Z;
            
            d.compute_tr_data(true,true);

        end

        function menu_tools_preferences(obj)
            profile = profile_controller.get_instance();
            profile.set_profile();
        end

        
        function menu_tools_estimate_irf(obj)
            d = obj.data_series_controller.data_series;
            estimate_irf_shift(d.tr_t_irf,d.tr_irf);
        end
        
        function menu_tools_add_pattern(obj)
            
            d = obj.data_series_controller.data_series;
            mask = obj.data_masking_controller.roi_controller.roi_mask;

            T = 1e6 / d.rep_rate;
            
            t = d.tr_t(:);
            data = d.get_roi(mask,obj.data_series_list.selected);
            data = mean(double(data),3);
            
            generate_pattern_ui(t,data,d.irf,T);

        end
		
        function menu_tools_edit_pattern_library(obj)
        end
        
        function menu_tools_denoise(obj)
            
            [file,path] = uigetfile({'*.sdt;*.tif;*.tiff;*.msr;*.bin;*.pt3;*.ptu;*.ffd;*.ffh;*.spc'},...
                'Choose Files',default_path,'MultiSelect','on');
            path = ensure_trailing_slash(path);
            if ~isempty(file)
                if ~iscell(file)
                    file = {file};
                end
                h = parfor_progressbar(length(file),'Denoising...');
                settings = denoise([path file{1}]);
                h.iterate(1);
                nfiles = length(file);
                parfor i=2:nfiles
                    denoise([path file{i}],settings);
                    h.iterate(1);
                end
                close(h);
            end
        end
        
        function menu_tools_estimate_q_q_sigma(obj)
            d = obj.data_series_controller.data_series;
        end
                
    end
    
end
