function download_flimfit_libraries(prompt_user)

    if nargin < 1
        prompt_user = false;
    end
    
    if isdeployed; return; end

    ver = get_git_version();

    if exist(['Libraries' filesep 'FLIMfitMex.' mexext ],'file')
       
        if ~exist(['Libraries' filesep 'LibraryVersion.txt'],'file'); return; end

        lib_ver = fileread(['Libraries' filesep 'LibraryVersion.txt']);
        if strcmp(lib_ver,ver); return; end
        
        disp(['Old library version found (' lib_ver '), clearing']);
        clear FLIMfitMex FlimReader
        delete('Libraries/*.*');

    end
        
    if prompt_user
       answer = questdlg('FLIMfit libraries are not compiled, would you like to download them?','FLIMfit Libraries','Yes','No','Yes');
       if strcmp(answer,'No'); return; end
    end

    platform = lower(computer());

    url = ['https://storage.googleapis.com/flimfit-downloads/latest/' ver '/libraries/flimfit_libraries_' platform '_' ver '.zip'];
    file = 'libraries.zip';

    websave(file,url);
    unzip(file);

    f = fopen(['Libraries' filesep 'LibraryVersion.txt'],'w');
    fwrite(f,ver);
    fclose(f);

    
end