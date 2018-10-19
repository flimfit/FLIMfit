function init_omero_bioformats(~,~)

    loadOmero();

    % find paths to OMEuiUtils.jar and ini4j.jar - approach copied from
    % bfCheckJavaPath

    jPath = javaclasspath;

    function findAndAddJar(jar)

        already_in_path = any(cellfun(@(x) contains(x,jar),jPath));

        if ~already_in_path
            path = which(jar);
            if isempty(path)
                path = fullfile(fileparts(mfilename('fullpath')), jar);
            end
            if ~isempty(path) && exist(path, 'file') == 2
                javaaddpath(path);
            else 
                assert(['Cannot automatically locate ' jar]);
            end
        end

    end

    if ~isdeployed
        findAndAddJar('OMEuiUtils.jar')
        findAndAddJar('ini4j.jar')
    end

    % verify that enough memory is allocated for bio-formats
    bfCheckJavaMemory();

    % load both bioformats & OMERO
    autoloadBioFormats = 1;

    % load the Bio-Formats library into the MATLAB environment
    status = bfCheckJavaPath(autoloadBioFormats);
    assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
        'to the static Java path or add it to the Matlab path.']);

    % initialize logging
    %loci.common.DebugTools.enableLogging('INFO');
    loci.common.DebugTools.enableLogging('ERROR');

end