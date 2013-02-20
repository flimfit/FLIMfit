function data_mapping = setup_data_mapping(obj,handles)

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

    mc = metaclass(obj);
    obj_prop = mc.Properties;
    handle_fields = fieldnames(handles);
        
    data_mapping = cell(0);
    
    for i=1:length(obj_prop)
        p = obj_prop{i}.Name;
        n = length(p);
        for j=1:length(handle_fields)
            h_field = handle_fields(j);
            if strncmp(p,h_field,n)
                data_mapping(end+1) = struct('property',p,'handle',handles.(handle_fields(j)),'type',h_field(n+1:end)); %#ok
            end
        end
    end

end