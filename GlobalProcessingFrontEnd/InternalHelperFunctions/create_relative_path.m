function str=create_relative_path(root,file)

    str = cell(1,length(file));
    for k=1:length(file)
        [path,name,ext] = fileparts(file{k});

        root_split = split(filesep,root);
        path_split = split(filesep,path);

        i=1;
        while i <= length(root_split) && i <= length(path_split) && strcmp(root_split{i},path_split{i})
            i=i+1;
        end

        s = [];
        if i>1
            for j=i:length(root_split)
                s = [s '..' filesep];
            end
        end
        for j=i:length(path_split)
           s = [s path_split{j} filesep]; 
        end

        s = [s name ext];
        
        str{k} = s;
    end
end