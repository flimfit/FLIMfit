function identify_flim_files(obj,root_path)

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

    if ~exist(root_path,'dir')
        throw(MException('FLIM:PathDoesNotExist','Path does not exist'));
    end

    root_path = ensure_trailing_slash(root_path);

    flim_files = cell(0);

    
    % Check for SDT files
    %-------------------------------------------------------------
    sdt_files = dir([root_path '*.sdt']);
        
    for i=1:length(sdt_files)
        [~,~,data_size] = LoadSDT(sdt_files(i).name,1,true); 
        flim_files(end+1) = ... 
            struct('DataType','TCSPC','Format','SDT','FileName',sdt_files(i).name,...
                   'DataSize',data_size); %#ok
    end
    
    % Check for TXT files
    %-------------------------------------------------------------
    sdt_files = dir([root_path '*.txt']);
        
    for i=1:length(txt_files)
        [~,~,data_size] = LoadSDT(sdt_files(i).name,1,true); 
        flim_files(end+1) = ... 
            struct('DataType','TCSPC','Format','TXT','FileName',sdt_files(i).name,...
                   'DataSize',data_size); %#ok
    end

end
