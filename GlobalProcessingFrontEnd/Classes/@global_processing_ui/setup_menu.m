
function handles = setup_menu(obj,handles)

    external = handles.external;
    session = handles.OMERO_session;
    
    if ~isempty(session)
      external = true;
        
      menu_OMERO      = uimenu(obj.window,'Label','OMERO');
   
      handles.menu_OMERO_fetch_TCSPC = uimenu(menu_OMERO,'Label','Fetch single TCSPC image from OMERO','Accelerator','O');
      handles.menu_OMERO_irf_TCSPC = uimenu(menu_OMERO,'Label','Fetch TCSPC irf from OMERO','Accelerator','O');
      handles.menu_OMERO_store_fit_result = uimenu(menu_OMERO,'Label','Store fit result into OMERO','Accelerator','O');
        
    end
    
    

    menu_file      = uimenu(obj.window,'Label','File');
    handles.menu_file_new_window = uimenu(menu_file,'Label','New Window','Accelerator','N');
    handles.menu_file_load_single = uimenu(menu_file,'Label','Load FLIM Data...','Accelerator','O','Separator','on');
    menu_file_load = uimenu(menu_file,'Label','Load FLIM Dataset');
    handles.menu_file_load_widefield = uimenu(menu_file_load,'Label','Load Widefield Dataset...','Accelerator','W');
    handles.menu_file_load_tcspc = uimenu(menu_file_load,'Label','Load TCSPC Dataset...','Accelerator','T');
    
    
    
    
    if ~external
        menu_file_load_pol = uimenu(menu_file,'Label','Load Polarisation Resolved Data');
        handles.menu_file_load_single_pol = uimenu(menu_file_load_pol,'Label','Load Single Image...','Accelerator','P');
        handles.menu_file_load_tcspc_pol = uimenu(menu_file_load_pol,'Label','Load TCSPC Dataset...','Separator','on','Accelerator','Y');
    
        handles.menu_file_reload_data = uimenu(menu_file,'Label','Reload Data...','Accelerator','R');
    
        handles.menu_file_save_dataset = uimenu(menu_file,'Label','Save FLIM Data...','Separator','on');
        handles.menu_file_save_raw = uimenu(menu_file,'Label','Save as Raw Dataset...');
    end
    
    handles.menu_file_set_default_path = uimenu(menu_file,'Label','Set Default Folder...','Separator','on','Accelerator','D');
    handles.menu_file_recent_default = uimenu(menu_file,'Label','Use Recent Default Folder');
    
    handles.menu_file_import_plate_metadata = uimenu(menu_file,'Label','Import Plate Metadata...','Separator','on');
    
    handles.menu_file_export_decay = uimenu(menu_file,'Label','Export Decay...','Separator','on');
    handles.menu_file_export_decay_series = uimenu(menu_file,'Label','Export Series Decay...');
    
    
    handles.menu_file_export_fit_params = uimenu(menu_file,'Label','Export Initial Fit Parameters...','Separator','on');
    handles.menu_file_import_fit_params = uimenu(menu_file,'Label','Import Initial Fit Parameters...');
    handles.menu_file_export_fit_results = uimenu(menu_file,'Label','Export Fit Results as HDF...','Separator','on');    
    handles.menu_file_import_fit_results = uimenu(menu_file,'Label','Import Fit Results as HDF...');
    
    handles.menu_file_export_fit_table = uimenu(menu_file,'Label','Export Fit Results Table...','Separator','on');
    handles.menu_file_export_plots = uimenu(menu_file,'Label','Export Images...');
    handles.menu_file_export_hist_data = uimenu(menu_file,'Label','Export Histograms...');
    
    menu_irf       = uimenu(obj.window,'Label','IRF');
    handles.menu_irf_load = uimenu(menu_irf,'Label','Load IRF...');
    if ~external
        handles.menu_irf_image_load = uimenu(menu_irf,'Label','Load Spatially Varying IRF...');
    end
    handles.menu_irf_recent = uimenu(menu_irf,'Label','Load Recent');
    
    handles.menu_irf_set_delta = uimenu(menu_irf,'Label','Set Delta Function IRF','Separator','on');
    
    handles.menu_irf_estimate_background = uimenu(menu_irf,'Label','Estimate IRF Background','Separator','on');
    handles.menu_irf_estimate_t0 = uimenu(menu_irf,'Label','Estimate IRF Shift','Separator','on');
    handles.menu_irf_estimate_g_factor = uimenu(menu_irf,'Label','Estimate G Factor');
    
    
    %handles.menu_irf_set_rectangular = uimenu(menu_irf,'Label','Set Rectangular IRF...');
    %handles.menu_irf_set_gaussian = uimenu(menu_irf,'Label','Set Gaussian IRF...');
    
    menu_background = uimenu(obj.window,'Label','Background');
    handles.menu_background_background_load = uimenu(menu_background,'Label','Load background image...');
    handles.menu_background_background_load_series = uimenu(menu_background,'Label','Load series of background image to smooth...');
    
    handles.menu_background_tvb_load = uimenu(menu_background,'Label','Load Time Varying Background...','Separator','on');
    handles.menu_background_tvb_use_selected = uimenu(menu_background,'Label','Use Selected Region as Time Varying Background');
    
    menu_segmentation = uimenu(obj.window,'Label','Segmentation');
    handles.menu_segmentation_yuriy = uimenu(menu_segmentation,'Label','Segmentation Manager');
    
    if ~external

        menu_tools = uimenu(obj.window,'Label','Tools');
        handles.menu_tools_photon_stats = uimenu(menu_tools,'Label','Determine Photon Statistics');
        handles.menu_tools_estimate_irf = uimenu(menu_tools,'Label','Estimate IRF');
        handles.menu_tools_create_irf_shift_map = uimenu(menu_tools,'Label','Create IRF Shift Map');
        %menu_batch = uimenu(obj.window,'Label','Batch Fitting');
        %handles.menu_batch_batch_fitting = uimenu(menu_batch,'Label','Batch Fit...');

        %menu_view = uimenu(obj.window,'Label','View');
        %handles.menu_view_chi2_display = uimenu(menu_view,'Label','Chi2 Viewer');

        menu_test = uimenu(obj.window,'Label','Test');
        handles.menu_test_test1 = uimenu(menu_test,'Label','Start Regression Tests','Accelerator','X');
        handles.menu_test_test2 = uimenu(menu_test,'Label','Test Fcn 2');
        handles.menu_test_test3 = uimenu(menu_test,'Label','Test Fcn 3');
        handles.menu_test_unload_dll = uimenu(menu_test,'Label','Unload DLL','Accelerator','U');
    end
    
    menu_help = uimenu(obj.window,'Label','Help');
    handles.menu_help_tracker = uimenu(menu_help,'Label','Open Issue Tracker...');
    handles.menu_help_bugs = uimenu(menu_help,'Label','File Bug Report...');
    
end
