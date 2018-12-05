function download_flimfit_libraries(prompt_user)

    if nargin < 1
        prompt_user = false;
    end

    if ~isdeployed && ~exist(['Libraries' filesep 'FLIMfitMex.' mexext ],'file')
        
        if prompt_user
           answer = questdlg('FLIMfit libraries are not compiled, would you like to download them?','FLIMfit Libraries','Yes','No','Yes');
           if strcmp(answer,'No'); return; end
        end
        
        [~,v] = system('git describe','-echo');
        v = strtrim(v);
        platform = lower(computer());
        
        url = ['https://storage.googleapis.com/flimfit-downloads/latest/' v '/libraries/flimfit_libraries_' platform '_' v '.zip'];
        file = 'libraries.zip';
        
        websave(file,url);
        unzip(file)
        
    end