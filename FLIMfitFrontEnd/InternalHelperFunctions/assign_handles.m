function assign_handles(obj,handles,callback)

    % Look through the struct handles for entries that 
    % have the same name as properties of object obj and
    % assign obj.p = handles.p.
    
    % Can help cut back on crud, but be careful not to copy unintended
    % properties!
    
    
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

    
    if nargin < 3
        callback = [];
    end

    mc = metaclass(obj);
    obj_prop = mc.Properties;
    handle_fields = fieldnames(handles);
    
    for i=1:length(obj_prop)
        p = obj_prop{i}.Name;
        for j=1:length(handle_fields)
            if strcmp(p,handle_fields{j})
                obj.(p) = handles.(p);
                if ~isempty(callback)
                    try
                        set(handles.(handle_fields{j}),'Callback',callback);
                    catch %#ok
                    end
                end
            end
        end
    end

end