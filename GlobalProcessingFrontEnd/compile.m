function compile(v)

    addpath_global_analysis();

    distrib_folder = 'X:\Group\Software\Global Analysis\';

    fid = fopen('GeneratedFiles\version.txt','w');
    fwrite(fid,v);
    fclose(fid);
    
    if is64
        sys = '64';
    else
        sys = '32';
    end

    try
    exe = ['DeployFiles\GlobalProcessing_' sys '.exe'];
    delete(exe);
    end
    
    eval(['deploytool -build GlobalProcessing_' sys '.prj']);
    
    while ~exist(exe,'file')
       pause(0.2);
    end
    
    deploy_folder = ['..\GlobalProcessingStandalone\GlobalProcessing_' v '_' sys];
    
    mkdir(deploy_folder);
    
    copyfile(exe,deploy_folder);
    
    if ~isempty(strfind(computer,'PCWIN'))
        lib_ext = 'dll';
    elseif ~isempty(strfind(computer,'MAC'))
        lib_ext = 'dylib';
    else
        lib_ext = 'so';
    end
    
    %copyfile(['DeployFiles\GlobalProcessing_' sys '.ctf'],deploy_folder);
    copyfile(['DeployFiles\Start_GlobalProcessing_' sys '.exe'],deploy_folder);
    copyfile(['..\GlobalProcessingLibrary\Libraries\FLIMGlobalAnalysis_' sys '.' lib_ext],deploy_folder);
    
    mkdir([distrib_folder 'GlobalProcessing_' v]);
    
    new_distrib_folder = [distrib_folder 'GlobalProcessing_' v filesep 'GlobalProcessing_' v '_' computer filesep];
    copyfile(deploy_folder,new_distrib_folder);
    
    
    chlog_file = [distrib_folder 'Changelog.txt'];
    f = fopen(chlog_file);
    
    l = fgetl(f);
    log = false;
    change = [];
    while ischar(l)
       if strcmp(l,['v' v])
           log = true;
       end
       if log
           change = [change l '\r\n'];
       end
       l = fgetl(f);
    end
    if isempty(change)
        change = ['v' v];
    end
    
    %{
    cd('..');
    %system('hg addremove');
    system(['hg commit -m "' v ' (' computer ')"']);
    cd('GlobalProcessingFrontEnd');
    %}
    
    try
        rmdir(['GlobalProcessing_' sys]);
    catch e %#ok
    end
    
end