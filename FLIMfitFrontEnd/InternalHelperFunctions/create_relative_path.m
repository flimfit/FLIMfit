function str=create_relative_path(root,file)

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