
function handles = setup_menu(obj,handles)

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
    
    %=================================

    menu_file      = uimenu(obj.window,'Label','File');
    handles.menu_file_new_window = uimenu(menu_file,'Label','New Window','Accelerator','N');
    handles.menu_file_load_single = uimenu(menu_file,'Label','Load FLIM Data...','Accelerator','O','Separator','on');
    menu_file_load = uimenu(menu_file,'Label','Load FLIM Data from Directory');
    handles.menu_file_load_tcspc = uimenu(menu_file_load,'Label','Load FLIM Dataset...','Accelerator','T');
    handles.menu_file_load_widefield = uimenu(menu_file_load,'Label','Load .tif stack Dataset...','Accelerator','Y');
    
    %handles.menu_file_load_plate = uimenu(menu_file,'Label','Load Plate data...','Accelerator','W');
    
    menu_file_load_pol = uimenu(menu_file,'Label','Load Polarisation Resolved Data');
    handles.menu_file_load_single_pol = uimenu(menu_file_load_pol,'Label','Load Single Image...','Accelerator','P');
    handles.menu_file_load_tcspc_pol = uimenu(menu_file_load_pol,'Label','Load FLIM Dataset...','Separator','on','Accelerator','Y');


    menu_file_acceptor = uimenu(menu_file,'Label','Acceptor Images...');
    handles.menu_file_load_acceptor = uimenu(menu_file_acceptor,'Label','Load Accceptor Images...');
    handles.menu_file_export_acceptor = uimenu(menu_file_acceptor,'Label','Export Acceptor Images...','Separator','on');
    handles.menu_file_import_acceptor = uimenu(menu_file_acceptor,'Label','Import Saved Acceptor Images...');


    handles.menu_file_reload_data = uimenu(menu_file,'Label','Reload Data...','Accelerator','R');

    %handles.menu_file_save_dataset = uimenu(menu_file,'Label','Save FLIM Data...','Separator','on');
    handles.menu_file_save_raw = uimenu(menu_file,'Label','Save as Raw Dataset...');
    handles.menu_file_save_magic_angle_raw = uimenu(menu_file,'Label','Save Magic Angle as Raw Dataset...');


    handles.menu_file_save_data_settings = uimenu(menu_file,'Label','Save Data Settings...','Separator','on');
    handles.menu_file_load_data_settings = uimenu(menu_file,'Label','Load Data Settings...');
    
  
    handles.menu_file_set_default_path = uimenu(menu_file,'Label','Set Default Folder...','Separator','on','Accelerator','D');
    handles.menu_file_recent_default = uimenu(menu_file,'Label','Use Recent Default Folder');
    
    handles.menu_file_import_plate_metadata = uimenu(menu_file,'Label','Import Plate Metadata...','Separator','on');
    handles.menu_file_export_exclusion_list = uimenu(menu_file,'Label','Export Exclusion List...');
    handles.menu_file_import_exclusion_list = uimenu(menu_file,'Label','Import Exclusion List...');    
    
    handles.menu_file_export_fit_params = uimenu(menu_file,'Label','Export Initial Fit Parameters...','Separator','on');
    handles.menu_file_import_fit_params = uimenu(menu_file,'Label','Import Initial Fit Parameters...');
    %handles.menu_file_export_fit_results = uimenu(menu_file,'Label','Export Fit Results as HDF...','Separator','on');    
    %handles.menu_file_import_fit_results = uimenu(menu_file,'Label','Import Fit Results as HDF...');
    
    handles.menu_file_export_intensity = uimenu(menu_file,'Label','Export Intensity Images...','Separator','on');
    handles.menu_file_export_fit_table = uimenu(menu_file,'Label','Export Fit Results Table...');
    handles.menu_file_export_plots = uimenu(menu_file,'Label','Export Images...');
    handles.menu_file_export_hist_data = uimenu(menu_file,'Label','Export Histograms...');
    
    handles.menu_file_exit = uimenu(menu_file,'Label','Quit','Separator','on');
      
    % OMERO MEGA MENU    
    %=================================
    menu_OMERO = uimenu(obj.window,'Label','OMERO');

    handles.menu_login = uimenu(menu_OMERO,'Label','Log in to OMERO...');

    %handles.menu_OMERO_Working_Data_Info = uimenu(menu_OMERO,'Label','Working Data have not been set up','ForegroundColor','red','Enable','off');

    menu_OMERO_Set_Data = uimenu(menu_OMERO,'Label','Set User...');
    %handles.menu_OMERO_Set_Dataset = uimenu(menu_OMERO_Set_Data,'Label','Dataset','Enable','off');
    %handles.menu_OMERO_Set_Plate = uimenu(menu_OMERO_Set_Data,'Label','SPW Plate','Enable','off');
    handles.menu_OMERO_Switch_User = uimenu(menu_OMERO_Set_Data,'Label','Switch User...','Separator','on','Enable','off');    

    handles.menu_OMERO_Connect_To_Another_User = uimenu(menu_OMERO_Set_Data,'Label','Connect to another user...','Enable','off');    
    handles.menu_OMERO_Connect_To_Logon_User = uimenu(menu_OMERO_Set_Data,'Label','Connect to logon user...','Enable','off');    

    handles.menu_OMERO_Reset_Logon = uimenu(menu_OMERO_Set_Data,'Label','Restore Logon...','Separator','on','Enable','off');                
    %
    handles.menu_OMERO_Load_FLIM_Data = uimenu(menu_OMERO,'Label','Load FLIM Data...','Separator','on','Enable','off');
    handles.menu_OMERO_Load_FLIM_Dataset = uimenu(menu_OMERO,'Label','Load FLIM Data from a Dataset...','Enable','off');
    
    %handles.menu_OMERO_Load_plate = uimenu(menu_OMERO,'Label','Load Plate data...','Enable','off');

    handles.menu_OMERO_Load_FLIM_Dataset_Polarization = uimenu(menu_OMERO,'Label','Load Polarization Resolved Data','Enable','off');        
    %
    handles.menu_OMERO_Load_irf = uimenu(menu_OMERO,'Label','Load IRF...','Separator','on','Enable','off'); 
    handles.menu_OMERO_Load_sv_irf = uimenu(menu_OMERO,'Label','Load Spatially Varying IRF...','Enable','off');
    handles.menu_OMERO_Load_Background = uimenu(menu_OMERO,'Label','Load Background...','Separator','on','Enable','off');    
    handles.menu_OMERO_Load_Background_average = uimenu(menu_OMERO,'Label','Load time-averaged background...','Separator','off','Enable','off');    
    
    
    handles.menu_OMERO_Load_tvb = uimenu(menu_OMERO,'Label','Load Time Varying Background...','Enable','off');                                    
    %handles.menu_OMERO_Export_tvb_Annotation = uimenu(menu_OMERO,'Label','Export Time Varying Background (Annotation)','Enable','off');  
    %
    %handles.menu_OMERO_load_acceptor = uimenu(menu_OMERO,'Label','Load Accceptor Images...','Separator','on','Enable','off');
    %handles.menu_OMERO_export_acceptor = uimenu(menu_OMERO,'Label','Export Acceptor Images...','Enable','off');
                            
    handles.menu_OMERO_save_data_settings = uimenu(menu_OMERO,'Label','Save Data Settings...','Separator','on','Enable','off');            
    handles.menu_OMERO_load_data_settings = uimenu(menu_OMERO,'Label','Load Data Settings...','Enable','off');    
    
    handles.menu_OMERO_export_fit_params = uimenu(menu_OMERO,'Label','Export Initial Fit Parameters...','Separator','on','Enable','off');            
    handles.menu_OMERO_import_fit_params = uimenu(menu_OMERO,'Label','Import Initial Fit Parameters...','Enable','off');    
    % 
    handles.menu_OMERO_export_fit_table = uimenu(menu_OMERO,'Label','Export Fit Results Table...','Separator','on','Enable','off');
    handles.menu_OMERO_export_plots = uimenu(menu_OMERO,'Label','Export Images...','Separator','off','Enable','off');
    handles.menu_OMERO_export_hist_data = uimenu(menu_OMERO,'Label','Export Histograms...','Separator','off','Enable','off');
    %
    % Commented out until we decide on a suitable file format (common to
    % both OMERO and file-side
    %handles.menu_OMERO_Export_Fitting_Results = uimenu(menu_OMERO,'Label','Export Fitting Results','Separator','on','Enable','off');
    %handles.menu_OMERO_Import_Fitting_Results = uimenu(menu_OMERO,'Label','Import Fitting Results for visualizing','Enable','off');        
    %===============================
       
    menu_irf       = uimenu(obj.window,'Label','IRF');
    handles.menu_irf_load = uimenu(menu_irf,'Label','Load IRF...');
    handles.menu_irf_image_load = uimenu(menu_irf,'Label','Load Spatially Varying IRF...');
  
    handles.menu_irf_recent = uimenu(menu_irf,'Label','Load Recent');
    
    handles.menu_irf_set_delta = uimenu(menu_irf,'Label','Set Delta Function IRF','Separator','on');
    
    handles.menu_irf_estimate_background = uimenu(menu_irf,'Label','Estimate IRF Background','Separator','on');
    handles.menu_irf_estimate_t0 = uimenu(menu_irf,'Label','Estimate IRF Shift','Separator','on');
    handles.menu_irf_estimate_g_factor = uimenu(menu_irf,'Label','Estimate G Factor');
    
    
    %handles.menu_irf_set_rectangular = uimenu(menu_irf,'Label','Set Rectangular IRF...');
    %handles.menu_irf_set_gaussian = uimenu(menu_irf,'Label','Set Gaussian IRF...');
    
    menu_background = uimenu(obj.window,'Label','Background');
    handles.menu_background_background_load = uimenu(menu_background,'Label','Load Background...');
    handles.menu_background_background_load_average = uimenu(menu_background,'Label','Load time-averaged background ...');
    
    handles.menu_background_tvb_load = uimenu(menu_background,'Label','Load Time Varying Background...','Separator','on');
    handles.menu_background_tvb_use_selected = uimenu(menu_background,'Label','Use Selected Region as Time Varying Background');
    
    menu_segmentation = uimenu(obj.window,'Label','Segmentation');
    handles.menu_segmentation_yuriy = uimenu(menu_segmentation,'Label','Segmentation Manager');
    
   

    menu_tools = uimenu(obj.window,'Label','Tools');
    handles.menu_tools_photon_stats = uimenu(menu_tools,'Label','Determine Photon Statistics');
    % experimental feature 
    %handles.menu_tools_estimate_irf = uimenu(menu_tools,'Label','Estimate IRF');
    handles.menu_tools_create_irf_shift_map = uimenu(menu_tools,'Label','Create IRF Shift Map...');
    handles.menu_tools_create_tvb_intensity_map = uimenu(menu_tools,'Label','Create TVB Intensity Map...');
    handles.menu_tools_fit_gaussian_irf = uimenu(menu_tools,'Label','Estimate IRF...');
    
    handles.menu_tools_preferences = uimenu(menu_tools,'Label','Preferences...','Separator','on');
   
    % NB odd naming in this menu allows easy movement of items back 
    % to their original location
    menu_advanced = uimenu(obj.window,'Label','Advanced');
    handles.menu_file_load_t_calibration = uimenu(menu_advanced,'Label','Load Time Point Calbration File...');
    handles.menu_advanced_rewrite_ome = uimenu(menu_advanced,'Label','Rewrite Lavision auto-save OME metadata...');
    
    menu_file_export_volume = uimenu(menu_advanced,'Label','Export Fit Results as volume...');    
    handles.menu_file_export_volume_to_icy = uimenu(menu_file_export_volume,'Label','Send to Icy...');
    handles.menu_file_export_volume_as_OMEtiff = uimenu(menu_file_export_volume,'Label','Save as OME.tiff...');
    handles.menu_file_export_volume_batch = uimenu(menu_file_export_volume,'Label','Batch-process data directory with current setup...');        

    % Test items need work - temporarily removed form GUI
    %menu_test = uimenu(obj.window,'Label','Test');
    %handles.menu_test_test1 = uimenu(menu_test,'Label','Start Regression Tests','Accelerator','X');
    %handles.menu_test_test2 = uimenu(menu_test,'Label','Test Fcn 2');
    %handles.menu_test_test3 = uimenu(menu_test,'Label','Test Fcn 3');
    %handles.menu_test_unload_dll = uimenu(menu_test,'Label','Unload DLL','Accelerator','U');

    
    menu_help = uimenu(obj.window,'Label','Help');
    handles.menu_help_about = uimenu(menu_help,'Label','About...');
    handles.menu_help_tracker = uimenu(menu_help,'Label','Open Issue Tracker...');
    handles.menu_help_bugs = uimenu(menu_help,'Label','File Bug Report...');
    handles.menu_help_check_version = uimenu(menu_help,'Label','Check for new version...');
end

