function init_pdftops(obj)

    if ~isdeployed
        if ispc
            path_ = [pwd '\pdftops.exe'];
        end
        if ismac
            path_ = [pwd '/pdftops.bin'];
        end
    else

        wait = true;
        if ispc
            path_ = [ctfroot '\FLIMfit\pdftops.exe'];
        end
        if ismac
            user_string('ghostscript','gs-noX11');
            path_ = [ctfroot '/FLIMfit/pdftops.bin'];
        end

    end

    % set up pdftops path
    user_string('pdftops',path_);

end
