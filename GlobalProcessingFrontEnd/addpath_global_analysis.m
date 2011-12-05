function addpath_global_analysis()

    if ~isdeployed
        thisdir = fileparts( mfilename( 'fullpath' ) );
        addpath(thisdir);
        addpath([thisdir filesep 'Classes']);
        addpath([thisdir filesep 'GUIDEInterfaces']);
        addpath([thisdir filesep 'GeneratedFiles']);
        addpath([thisdir filesep 'HelperFunctions']);
        addpath([thisdir filesep 'HelperFunctions' filesep 'GUILayout-v1p8']);
        addpath([thisdir filesep 'HelperFunctions' filesep 'GUILayout-v1p8' filesep 'Patch']);
        addpath([thisdir filesep 'HelperFunctions' filesep 'GUILayout-v1p8' filesep 'layoutHelp']);
        addpath([thisdir filesep '..' filesep 'GlobalProcessingLibrary' filesep 'Libraries']);
    end

end