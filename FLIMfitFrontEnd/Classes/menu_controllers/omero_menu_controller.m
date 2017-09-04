classdef omero_menu_controller < handle
    
    
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
        omero_logon_manager;     
        data_series_controller;
        fitting_params_controller;
        fit_controller;
        hist_controller;
        
        menu_OMERO_Working_Data_Info;
    end
        
    
    methods
        
        function obj = omero_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
        end
        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function menu_login(obj)
            obj.omero_logon_manager.Omero_logon();
            
            if ~isempty(obj.omero_logon_manager.session)
                props = properties(obj);
                OMERO_props = props( strncmp('menu_OMERO',props,10) );
                for i=1:length(OMERO_props) 
                    set(obj.(OMERO_props{i}),'Enable','on');
                end
            end
            
        end
        %------------------------------------------------------------------
        function menu_OMERO_Set_Dataset(obj)            
            infostring = obj.omero_logon_manager.Set_Dataset();
            if ~isempty(infostring)
                set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue');
            end;
        end                        
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Data(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, true);
            images = chooser.getSelectedImages();
            clear chooser;
            if images.length > 0
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                % NB misnomer "load_single" retained for compatibility with
                % file-side
                obj.data_series_controller.data_series = OMERO_data_series();
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;
                obj.data_series_controller.load_single(images);
                notify(obj.data_series_controller,'new_dataset');
            end
        end                                  
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Dataset(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(1));
            dataset = chooser.getSelectedDataset();
            clear chooser;
            if ~isempty(dataset)
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_data_series(dataset,''); 
                notify(obj.data_series_controller,'new_dataset');
            end   
        end    
        %------------------------------------------------------------------        
        function menu_OMERO_Load_plate(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(2));
            plate = chooser.getSelectedPlate();
            clear chooser;
            if ~isempty(plate)
                % clear & delete existing data series
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_plate(plate); 
                obj.data_series_controller.data_series.plateId = plate.getId().getValue();
                notify(obj.data_series_controller,'new_dataset');
            end
        end  
                    
        %------------------------------------------------------------------
        function menu_OMERO_Load_irf(obj)
            
            [image, selected] = obj.load_image_or_attachment;
           
            if ~isempty(image)
                  load_as_image = false;
                  obj.data_series_controller.data_series.load_irf(image,load_as_image);
            else
                if ~isempty(selected)
                    obj.data_series_controller.data_series.load_irf(selected);
                    if isa(selected,char)
                        delete(selected);
                    end
                end
            end
        end
    
        %------------------------------------------------------------------
        function [image, file] = load_image_or_attachment(obj)
            % common functionality for OMERO_load_irf load 
            % and OMERO_load_tvb
            
            images = [];
            image = [];
            file = [];
                            
            dId = obj.data_series_controller.data_series.datasetId;
            pId = obj.data_series_controller.data_series.plateId;
            
            if pId > 0
                % plate so attachment only 
                chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(7), java.lang.Long(pId));
                selected = chooser.getSelectedFile();
            else
                chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(8),java.lang.Long(dId));
                images = chooser.getSelectedImages();
                selected = chooser.getSelectedFile();
            end
            clear chooser;
            if images.length == 1
                  image = images(1);
            else
                if ~isempty(selected)
                    
                     fname = char(selected.getName().getValue());
                     [~,~,ext] = fileparts_inc_OME(fname);
                    
                    % NB marshal-object is overloaded in OMERO_data_series 
                    % load_irf etc use marshal_object for .xml files so 
                    % simply return selected file
                    
                    if strcmp(ext,'.xml')
                        file = selected;
                    else 
                        fullpath  = [tempdir fname];
                        getOriginalFileContent(obj.omero_logon_manager.session, selected, fullpath);
                        file = fullpath;
                    end
                end
            end
          end                    
        %------------------------------------------------------------------
        function menu_OMERO_Load_sv_irf(obj)
            dId = obj.data_series_controller.data_series.datasetId;
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(0),java.lang.Long(dId));
            images = chooser.getSelectedImages();
            clear chooser;
            if images.length == 1
                  load_as_image = true;
                  obj.data_series_controller.data_series.load_irf(images(1),load_as_image)
            end  
        end
        %------------------------------------------------------------------
        function menu_OMERO_Load_Background(obj)                                     
            dId = obj.data_series_controller.data_series.datasetId;
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, java.lang.Long(dId));
            images = chooser.getSelectedImages();
            if images.length == 1
                obj.data_series_controller.data_series.load_background(images(1), false)
            end
            clear chooser;                     
        end                            
        %------------------------------------------------------------------
         function menu_OMERO_Load_Background_average(obj)                                     
            dId = obj.data_series_controller.data_series.datasetId;
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, java.lang.Long(dId) );
            images = chooser.getSelectedImages();
            if images.length == 1
                obj.data_series_controller.data_series.load_background(images(1),true)
            end
            clear chooser;                     
        end  
                          
       
        %------------------------------------------------------------------        
        function menu_OMERO_Reset_Logon(obj)
            obj.omero_logon_manager.Omero_logon();
        end
       
        
        %------------------------------------------------------------------                
        function menu_OMERO_Switch_User(obj)
            obj.omero_logon_manager.Omero_logon();
        end    
        
        %------------------------------------------------------------------
        function menu_OMERO_Load_tvb(obj)
            
            [image, selected] = obj.load_image_or_attachment;
           
            if ~isempty(image)
                  obj.data_series_controller.data_series.load_tvb(image);
            else
                if ~isempty(selected)
                    obj.data_series_controller.data_series.load_tvb(selected);
                    if isa(selected,char)
                        delete(selected);
                    end
                end
            end
        end
    
        %------------------------------------------------------------------        
        function menu_OMERO_Load_FLIM_Dataset_Polarization(obj)
            
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(1));
            dataset = chooser.getSelectedDataset();
            clear chooser;
            if ~isempty(dataset)
                if isvalid(obj.data_series_controller.data_series)
                    obj.data_series_controller.data_series.clear();
                end
                obj.data_series_controller.data_series = OMERO_data_series();   
                obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;  
                obj.data_series_controller.load_data_series(dataset,'',true); 
                notify(obj.data_series_controller,'new_dataset');
            end
            
            
        end             
                          
        %------------------------------------------------------------------
        function menu_OMERO_load_data_settings(obj)
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(6));
            selected = chooser.getSelectedFile();
            clear chooser;
            if ~isempty(selected)
                 fname = char(selected.getName().getValue());
                 [~,~,ext] = fileparts_inc_OME(fname);
                  if strcmp(ext,'.xml')
                      obj.data_series_controller.data_series.load_data_settings(fname);
                  else
                      errordlg('Please select a .xml file')
                  end
            end
        end                                            
                                          
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Another_User(obj)
            obj.omero_logon_manager.Select_Another_User();
            %set(obj.menu_OMERO_Working_Data_Info,'Label','Working Data have not been set up','ForegroundColor','red');
        end                            
        %------------------------------------------------------------------
        function menu_OMERO_Connect_To_Logon_User(obj)            
            obj.omero_logon_manager.userid = obj.omero_logon_manager.session.getAdminService().getEventContext().userId;
            obj.omero_logon_manager.project = [];
            obj.omero_logon_manager.dataset = [];
            obj.omero_logon_manager.screen = [];
            obj.omero_logon_manager.plate = [];
            %set(obj.menu_OMERO_Working_Data_Info,'Label','Working Data have not been set up','ForegroundColor','red');
        end                            
        %------------------------------------------------------------------                
        function menu_OMERO_Import_Fitting_Results(obj)  
            obj.data_series_controller.data_series.clear();    % ensure delete if multiple handles
            obj.data_series_controller.data_series = OMERO_data_series();
            obj.data_series_controller.data_series.omero_logon_manager = obj.omero_logon_manager;
            %infostring = obj.data_series_controller.data_series.load_fitted_data(obj.fit_controller);
            %if ~isempty(infostring)
            %    set(obj.menu_OMERO_Working_Data_Info,'Label',infostring,'ForegroundColor','blue');            
            %end;            
        end                                    
        %------------------------------------------------------------------                
        function menu_OMERO_load_acceptor(obj)
            obj.omero_logon_manager.Load_Acceptor_Images(obj.data_series_controller.data_series);
        end
        %------------------------------------------------------------------                
        function menu_OMERO_export_acceptor(obj)
            obj.omero_logon_manager.Export_Acceptor_Images(obj.data_series_controller.data_series);
        end
                

        
        function menu_OMERO_export_fit_params(obj)
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('root filename', 'fit_parameters', '.xml');
            if filename ~= 0
                obj.fitting_params_controller.save_fitting_params([pathname filename]);         
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                            dataset, ...
                            char('application/octet-stream'), ...
                            [pathname filename], ...
                            '', ...
                            'IC_PHOTONICS');  
            end
        end
        
        function menu_OMERO_import_fit_params(obj)
            chooser = OMEuiUtils.OMEROImageChooser(obj.omero_logon_manager.client, obj.omero_logon_manager.userid, int32(6));
            selected = chooser.getSelectedFile();
            clear chooser;
            if ~isempty(selected)
                fname = char(selected.getName().getValue());
                [~,~,ext] = fileparts_inc_OME(fname);
                
                if ~strcmp(ext,'.xml')
                    errordlg('Plese select a .xml file!');
                    return;
                end;
                
                fullpath  = [tempdir fname];
                getOriginalFileContent(obj.omero_logon_manager.session, selected, fullpath);
                obj.fitting_params_controller.load_fitting_params(fullpath); 
                delete(fullpath);
               
            end
        end      
        
        function menu_OMERO_save_data_settings(obj)
          
            [filename, ~, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.xml');
            if filename ~= 0
                obj.data_series_controller.data_series.save_data_settings(filename, dataset);         
            end
        end

        function menu_OMERO_export_fit_table_callback(obj)
            
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('filename', '', '.csv');
            if filename ~= 0
                obj.fit_controller.save_param_table([pathname filename]);         
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                            dataset, ...
                            char('application/octet-stream'), ...
                            [pathname filename], ...
                            '', ...
                            'IC_PHOTONICS');  
            end
        end
        
        function menu_OMERO_export_hist_data(obj)
            
            [filename,pathname, dataset] = obj.data_series_controller.data_series.prompt_for_export('root filename', '', '.txt');
            if filename ~= 0
                fname = obj.hist_controller.export_histogram_data([pathname filename]);
                add_Annotation(obj.omero_logon_manager.session, obj.omero_logon_manager.userid, ...
                    dataset, ...
                    char('application/octet-stream'), ...
                    fname, ...
                    '', ...
                    'IC_PHOTONICS');
            end
        end
        
        function menu_OMERO_export_plots_callback(obj, ~, ~)
            
            if isa(obj.data_series_controller.data_series,'flim_data_series')
                errordlg('Not yet implemented for data not loaded from OMERO!');
                return;
            end 
            
            default_name = [char(obj.omero_logon_manager.dataset.getName().getValue() ) 'fit'];
            [filename, pathname, dataset, before_list] = obj.data_series_controller.data_series.prompt_for_export('root filename', default_name, '.tiff');
            obj.plot_controller.update_plots([pathname filename]);
            obj.data_series_controller.data_series.export_new_images(pathname,filename,before_list, dataset);
            
        end
        
       
        
    end
    
end
