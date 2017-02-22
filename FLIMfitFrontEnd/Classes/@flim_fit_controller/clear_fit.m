function clear_fit(obj)

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


    had_fit = obj.has_fit;
    obj.has_fit = false;

    if ishandle(obj.fit_result)
        delete(obj.fit_result);
    end
    obj.fit_result = flim_fit_result();
    
    obj.dll_interface.clear_fit();
    
    set(obj.results_table,'ColumnName',[]);
    set(obj.results_table,'Data',[]);    

    set(obj.progress_table,'ColumnName',[]);
    set(obj.progress_table,'Data',[]);    

    if had_fit
        notify(obj,'fit_updated');
    end
end