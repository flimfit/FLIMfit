function new_folders = get_folders_recursive(root_path)

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren


    folders = dir(root_path);
    folders = struct2cell(folders);
    folder_isdir = cell2mat(folders(4,:));
    folder_name = folders(1,:);

    % N.B.in  folder_isdir 0 indicates a folder
    sel = folder_isdir == 0 & ~strncmp('.',folder_name,1);
   
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