function init_pdftops()

    if ispc
        ext = '.exe';
    elseif ismac
        ext = '.bin';
    end

    if ~isdeployed
        path = [pwd 'ThirdParty' filesep 'pdftops' filesep 'pdftops' ext];
    else
        path = [ctfroot filesep 'FLIMfit' filesep 'pdftops' ext];
        if ismac
            user_string('ghostscript','gs-noX11');
        end
    end

    % set up pdftops path
    user_string('pdftops',path);

end
