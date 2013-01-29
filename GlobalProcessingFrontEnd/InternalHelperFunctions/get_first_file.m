function file = get_first_file(folder)
    %> Get the first tif file in a folder
    
    file = [];
    j=1;
    
    contents = dir(folder);
    
    while(isempty(file) && j<=length(contents))
        if ~contents(j).isdir && ~isempty( strfind(contents(j).name,'.tif') )
            file = [folder filesep contents(j).name];
        end
        j = j+1;
    end

end