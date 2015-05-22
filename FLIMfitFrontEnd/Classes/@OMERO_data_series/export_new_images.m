function export_new_images(obj,pathname,filename,before_list, dId)
    %> exports all images that are not in before_list to an OMERO Dataset
    
    % Copyright (C) 2015 Imperial College London.
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

    c = strsplit(filename,'.');
    search_string = [pathname c{1} '*.*'];
    after_list = dir(search_string);
    if ~isempty(before_list)
        s = [after_list(:).datenum];
        [s,~] = sort(s);
        after_list = {after_list(s).name}; % Cell array of names in order by datenum.
        after_list = after_list(length(before_list)+1:end); %keep only the new ones
    else
        after_list = {after_list(:).name};
    end
    add_Images(obj.omero_data_manager,pathname,after_list, dId);
                
   
end