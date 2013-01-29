function GlobalProcessingExternalOMERO()

    addpath_global_analysis();
    
    wait            = false;
    OMERO_active    = true;
    external        = true;
    require_auth    = false;
    global_processing_ui(wait,OMERO_active,external,require_auth);
    
    %global_processing_ui(false, true );
    
end

