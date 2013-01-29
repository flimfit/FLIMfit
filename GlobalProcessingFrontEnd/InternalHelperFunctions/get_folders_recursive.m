function new_folders = get_folders_recursive(root_path)

    folders = dir(root_path);
    folders = struct2cell(folders);
    folder_isdir = cell2mat(folders(4,:));
    folder_name = folders(1,:);

    sel = folder_isdir == 1 & ~strncmp('.',folder_name,1);

    folders = folder_name(sel);

    new_folders = [];

    cellf = @(fun, arr) cellfun(fun, num2cell(arr), 'uniformoutput',0);

    while ~isempty(folders)

        sb =  java.io.File([root_path folders{1}]);
        sb = sb.listFiles();

        if ~isempty(sb)
            sb = cell(sb);
            subfolder_isdir = cellfun(@(x) x.isDirectory(),sb);
            subfolder_name = cellfun(@(x) cell(x.getName()),sb);
            subfolder_is_fi = strncmp(subfolder_name,'FI',2);

            if ~any(subfolder_isdir & ~subfolder_is_fi)
                new_folders{end+1} = folders{1};
            else
                subfolder_name = subfolder_name(subfolder_isdir);
                subfolder_name = strcat([folders{1} filesep], subfolder_name);
                folders = [folders subfolder_name'];
            end
        else
            new_folders{end+1} = folders{1};
        end
        
        if length(folders)>1
            folders = folders(2:end);
        else
            folders = [];
        end

    end
end