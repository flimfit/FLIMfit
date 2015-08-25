function file = FindFile(folder, search_str, ext, file_type)
    files = dir([folder filesep search_str ext]);
    if isempty(files)
        file = uigetfile(['*' ext], ['Choose ' file_type ' File'], folder);
    else
        file = files(1).name;
    end
    file = [folder filesep file];        
end
