function [v, is_release] = get_git_version()
    [err,v] = system('git describe --abbrev=8','-echo');
    version_file = ['GeneratedFiles' filesep 'version.txt'];

    if err == 0
        v = v(1:end-1);
        v = strtrim(v);
        is_release = isempty(regexp(v,'-\d-+[a-z0-9]+','ONCE'));
    elseif exist(version_file,'file')
        v = fileread(version_file);
    else
        throw(MException('FLIMfit:couldNotReadVersion','Could not read version'));
    end    
end