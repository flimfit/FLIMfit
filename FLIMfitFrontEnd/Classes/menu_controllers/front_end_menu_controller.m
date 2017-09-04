classdef front_end_menu_controller < handle
    
    % OBSOLETE
    
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
                               
        menu_file_new_window;
        
        menu_file_load_single;
        menu_file_load_widefield;
        menu_file_load_tcspc;
        menu_file_load_plate;
        
        menu_file_load_single_pol;
        menu_file_load_tcspc_pol;
        
        menu_file_load_acceptor;
        menu_file_export_acceptor;
        menu_file_import_acceptor;
        
        menu_file_reload_data;
        
        menu_file_save_dataset;
        menu_file_save_raw;
        menu_file_save_magic_angle_raw;
        
        menu_file_export_decay;
        menu_file_export_decay_series;
        
        menu_file_set_default_path;
        menu_file_recent_default
        
        menu_file_load_raw;
        
        menu_file_load_data_settings;
        menu_file_save_data_settings;
        
        menu_file_load_t_calibration;
        
        menu_file_open_fit;
        menu_file_save_fit;
        
        menu_file_export_plots;
        menu_file_export_hist_data;
        
        menu_file_import_plate_metadata;
        
        menu_file_export_fit_table;
        
        menu_file_load_model;
        menu_file_save_model;
        menu_tools_edit_model_library;
        
        
        menu_file_import_fit_results;
        menu_file_export_fit_results;
        
        menu_file_import_exclusion_list;
        menu_file_export_exclusion_list;
        
        menu_file_export_intensity;
            
        menu_file_exit;
        
        % icy..
        menu_file_export_volume_to_icy;
        menu_file_export_volume_as_OMEtiff;
        menu_file_export_volume_batch;
        
        menu_irf_load;
        menu_irf_image_load;
        menu_irf_set_delta;
        
        menu_irf_estimate_t0;
        menu_irf_estimate_g_factor;
        menu_irf_estimate_background;
        %menu_irf_set_rectangular;
        %menu_irf_set_gaussian;
        menu_irf_recent;
        
        menu_background_background_load;
        menu_background_background_load_average;
        %menu_background_background_load_series;
        
        menu_background_tvb_load;
        menu_background_tvb_use_selected;
        
        menu_segmentation_yuriy;
        menu_segmentation_phasor;

        menu_tools_photon_stats;
        menu_tools_estimate_irf;
        menu_tools_create_irf_shift_map;
        menu_tools_create_tvb_intensity_map;
        menu_tools_fit_gaussian_irf;
        menu_tools_preferences;
        
        menu_tools_add_pattern;
        menu_tools_edit_pattern_library;
                
        menu_test_test1;
        menu_test_test2;
        menu_test_test3;
        menu_test_unload_dll;
        
        menu_help_about;
        menu_help_bugs;
        menu_help_tracker;
        menu_help_check_version;
        
        menu_batch_batch_fitting;
        
        model_controller;
        data_series_list;
        data_series_controller;
        data_decay_view;
        fit_controller;
        fitting_params_controller;
        plot_controller;
        hist_controller;
        data_masking_controller;
        
        recent_irf;
        recent_default_path;

        platform_default_path; 
        default_path;
        window;

    end

    
    
    methods
        function obj = front_end_menu_controller(handles)
            assign_handles(obj,handles);
            set_callbacks(obj);            
        end
        
        function set_callbacks(obj)
            
             mc = metaclass(obj);
             obj_prop = mc.Properties;
             obj_method = [mc.Methods{:}];
             
             
             % Search for properties with corresponding callbacks
             for i=1:length(obj_prop)
                prop = obj_prop{i}.Name;
                if strncmp(prop,'menu_',5)
                    method = [prop '_callback'];
                    matching_methods = findobj(obj_method,'Name',method);
                    if ~isempty(matching_methods)  
                        fcn = eval(['@obj.' method]);
                        set(obj.(prop),'Callback',@(x,y) EC(fcn));
                    end
                end          
             end
             
        end
        

        
        %------------------------------------------------------------------
        % Batch Fit
        %------------------------------------------------------------------
        function menu_batch_batch_fitting_callback(obj)
            folder = uigetdir(obj.default_path,'Select the folder containing the datasets');
            if folder ~= 0
                settings_file = tempname;
                fit_params = obj.fitting_params_controller.fit_params;
                obj.data_series_controller.data_series.save_dataset_indextings(settings_file);
                batch_fit(folder,'widefield',settings_file,fit_params);
                if strcmp(obj.default_path,obj.platform_default_path)
                    obj.default_path = path;
                end
            end
            
        end
        
      
       

  
        function menu_test_test2_callback(obj)
            
            d = obj.data_series_controller.data_series;

            tr_acceptor = zeros(size(d.acceptor));

            [optimizer, metric] = imregconfig('multimodal'); 
            optimizer.MaximumIterations = 40;
            h = waitbar(0,'Aligning...');

            for i=1:d.n_datasets
            
                a = d.acceptor(:,:,i);
                intensity = d.integrated_intensity(i);
                %try
                    t = imregtform(a,intensity,'rigid',optimizer,metric);
                    dx = t.T(3,1:2);
                    dx = norm(dx);
                    disp(dx);
                    
                    if dx>200
                        tr = a;
                    else
                        tr = imwarp(a,t,'OutputView',imref2d(size(intensity)));
                    end

                %catch e
                %    tr = a;
                %end
                
                tr_acceptor(:,:,i) = tr;
                
                figure(13);
                
                subplot(1,2,1)
                a = a - min(a(:));
                im(:,:,1) = a ./ max(a(:));
                im(:,:,2) = intensity ./ max(intensity(:));
                im(:,:,3) = 0;
                
                im(im<0) = 0;
                
                imagesc(im);
                daspect([1 1 1]);
                set(gca,'XTick',[],'YTick',[]);
                title('Before Alignment');
                

                subplot(1,2,2)
                tr = tr - min(tr(:));
                im(:,:,1) = tr ./ max(tr(:));
                im(:,:,2) = intensity ./ max(intensity(:));
                im(:,:,3) = 0;
                
                im(im<0) = 0;
                
                imagesc(im);
                daspect([1 1 1]);
                set(gca,'XTick',[],'YTick',[]);
                title('After Alignment');
                
                waitbar(i/d.n_datasets,h);
            end
            
            global acceptor;
            acceptor = tr_acceptor;
            %save('C:\Users\scw09\Documents\00 Local FLIM Data\2012-10-17 Rac COS Plate\acceptor_images.mat','acceptor');
            close(h);            
            
        end
        
        function menu_test_test3_callback(obj)
            
            d = obj.data_series_controller.data_series;
            
            
            images = d.acceptor;
            names = d.names;
            description = 'Acceptor';
            file = 'c:\users\scw09\documents\acceptor.tiff';
            
            %SaveFPTiffStack(file,images,names,description)
            
            %return ;
            
            l_images = ReadSelectedFromTiffStack(file,names,description);
            
            %file = 'c:\users\scw09\documents\data_serialization.h5';
            
            %obj.data_series_controller.data_series.serialize(file);
            
            %{
            global fg fh;
            r = obj.fit_controller.fit_result;
            
            im = r.get_image(1,'tau_1');
            I = r.get_image(1,'I');
            dim = 2;
            color = {'b', 'r', 'm', 'g', 'k'};
            s = nanstd(im,0,dim);
            m = nanmean(im,dim);
            I = nanmean(I,dim);
            figure(fg);
            hold on;
            fh(end+1) = plot(s,color{length(fh)+1});
            ylim([0 500]);
            %}
        end
        
        
        
        
     end
    
end

