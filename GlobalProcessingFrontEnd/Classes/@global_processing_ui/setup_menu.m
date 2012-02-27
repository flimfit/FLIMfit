
function setup_menu(obj)

    handles = guidata(obj.window);

    menu_file      = uimenu(obj.window,'Label','File');
    handles.menu_file_new_window = uimenu(menu_file,'Label','New Window','Accelerator','N');
    menu_file_load = uimenu(menu_file,'Label','Load FLIM Data','Separator','on');
    handles.menu_file_load_single = uimenu(menu_file_load,'Label','Load Single Image...','Accelerator','O');
    handles.menu_file_load_widefield = uimenu(menu_file_load,'Label','Load Widefield Dataset...','Accelerator','W','Separator','on');
    handles.menu_file_load_tcspc = uimenu(menu_file_load,'Label','Load TCSPC Dataset...','Accelerator','T');
    menu_file_load_pol = uimenu(menu_file,'Label','Load Polarisation Resolved Data');
    handles.menu_file_load_single_pol = uimenu(menu_file_load_pol,'Label','Load Single Image...','Accelerator','P');
    handles.menu_file_load_tcspc_pol = uimenu(menu_file_load_pol,'Label','Load TCSPC Dataset...','Separator','on','Accelerator','Y');
    
    handles.menu_file_load_raw = uimenu(menu_file,'Label','Load Raw Data...');
    handles.menu_file_load_test = uimenu(menu_file,'Label','Load Test Data...');
    handles.menu_file_reload_data = uimenu(menu_file,'Label','Reload Data...','Accelerator','R');
    
    handles.menu_file_save_dataset = uimenu(menu_file,'Label','Save FLIM Data...','Separator','on');
    handles.menu_file_save_raw = uimenu(menu_file,'Label','Save as Raw Dataset...');
    
    handles.menu_file_export_decay = uimenu(menu_file,'Label','Export Decay...','Separator','on');
    handles.menu_file_export_decay_series = uimenu(menu_file,'Label','Export Series Decay...');
    
    
    handles.menu_file_set_default_path = uimenu(menu_file,'Label','Set Default Folder...','Separator','on','Accelerator','D');
    handles.menu_file_export_fit_params = uimenu(menu_file,'Label','Export Initial Fit Parameters...','Separator','on');
    handles.menu_file_import_fit_params = uimenu(menu_file,'Label','Import Initial Fit Parameters...');
    handles.menu_file_export_fit_results = uimenu(menu_file,'Label','Export Fit Results...','Separator','on');
    handles.menu_file_import_fit_results = uimenu(menu_file,'Label','Import Fit Results...');
    handles.menu_file_export_fit_table = uimenu(menu_file,'Label','Export Fit Results Table...','Separator','on');

    handles.menu_file_export_plots = uimenu(menu_file,'Label','Export Plots...','Separator','on');
    handles.menu_file_export_hist_data = uimenu(menu_file,'Label','Export Histograms...');
    
    menu_irf       = uimenu(obj.window,'Label','IRF');
    handles.menu_irf_load = uimenu(menu_irf,'Label','Load IRF...');
    handles.menu_irf_set_delta = uimenu(menu_irf,'Label','Set Delta Function IRF','Separator','on');
    handles.menu_irf_set_rectangular = uimenu(menu_irf,'Label','Set Rectangular IRF...');
    handles.menu_irf_set_gaussian = uimenu(menu_irf,'Label','Set Gaussian IRF...');
    
    menu_background = uimenu(obj.window,'Label','Background');
    handles.menu_background_background_load = uimenu(menu_background,'Label','Load background image...');
    handles.menu_background_background_load_series = uimenu(menu_background,'Label','Load series of background image to smooth...');
    
    menu_segmentation = uimenu(obj.window,'Label','Segmentation');
    handles.menu_segmentation_yuriy = uimenu(menu_segmentation,'Label','Segmentation Manager');
    
    menu_batch = uimenu(obj.window,'Label','Batch Fitting');
    handles.menu_batch_batch_fitting = uimenu(menu_batch,'Label','Batch Fit...');
    
    menu_view = uimenu(obj.window,'Label','View');
    handles.menu_view_chi2_display = uimenu(menu_view,'Label','Chi2 Viewer');
    
    menu_test = uimenu(obj.window,'Label','Test');
    handles.menu_test_test1 = uimenu(menu_test,'Label','Test Fcn 1','Accelerator','X');
    
    
    guidata(obj.window,handles);

end
