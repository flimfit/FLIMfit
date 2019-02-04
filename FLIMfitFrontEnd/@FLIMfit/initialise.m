function initialise(obj)

    addpath_global_analysis();

    splash = set_splash('FLIMfit-logo-colour.png');
    download_flimfit_libraries(true);
    upgrade_pattern_library();

    diagnostics('program','start');
    flim_fit_ui.check_prefs();

    init_pdftops();
    init_omero_bioformats();

    profile = profile_controller.get_instance();
    profile.load_profile();


    if ~isdeployed
        addpath_global_analysis();
    end

    v = read_version();

    obj.window = flim_fit_ui.open_window(v);

    h.version = v;
    h.window = obj.window;
    h.use_popup = true;

    h = flim_fit_ui.setup_layout(h.window, h);                        
    h = flim_fit_ui.setup_toolbar(h.window, h);

    h.model_controller = flim_model_controller(h.model_panel);            
    h.data_series_list = flim_data_series_list(h);
    h.data_series_controller = flim_data_series_controller(h);                                    
    h.omero_logon_manager = flim_omero_logon_manager(h);

    h.fitting_params_controller = flim_fitting_params_controller(h);
    h.data_intensity_view = flim_data_intensity_view(h);
    h.roi_controller = roi_controller(h);                                                   
    h.fit_controller = flim_fit_controller(h);   
    h.result_controller = flim_result_controller(h);
    h.data_decay_view = flim_data_decay_view(h);
    h.data_masking_controller = flim_data_masking_controller(h);
    h.irf_controller = irf_controller(h);
    h.plot_controller = flim_fit_plot_controller(h);
    h.gallery_controller = flim_fit_gallery_controller(h);
    h.hist_controller = flim_fit_hist_controller(h);
    h.corr_controller = flim_fit_corr_controller(h);
    h.graph_controller = flim_fit_graph_controller(h);
    h.platemap_controller = flim_fit_platemap_controller(h);            

    h.project_controller = flim_project_controller(h);

    h = flim_fit_ui.setup_menu(h.window, h);            
    h.file_menu_controller = file_menu_controller(h);
    h.omero_menu_controller = omero_menu_controller(h);
    h.irf_menu_controller = irf_menu_controller(h);
    h.misc_menu_controller = misc_menu_controller(h);
    h.tools_menu_controller = tools_menu_controller(h);
    h.help_menu_controller = help_menu_controller(h);
    h.icy_menu_controller = icy_menu_controller(h);

    guidata(obj.window,h);            
    assign_handles(obj,h);

    close(splash);
    set(obj.window,'Visible','on');

end