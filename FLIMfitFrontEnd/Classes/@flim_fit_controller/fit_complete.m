function fit_complete(obj,~,~)

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

    stop(obj.fit_timer);
    obj.fit_timer = [];
    
    if ishandleandvalid(obj.wait_handle)
        obj.wait_handle.StatusMessage = 'Processing Fit Results...';
        obj.wait_handle.Indeterminate = true;
    end
    
    obj.fit_result = obj.dll_interface.get_fit_result();
    
    obj.display_fit_end();

    obj.has_fit = true;
    obj.fit_in_progress = false;
    obj.terminating = false;
            
    t_exec = toc(obj.start_time);    
    disp(['Total execution time: ' num2str(t_exec)]);
       
    if ishandleandvalid(obj.wait_handle)
        close(obj.wait_handle);
        obj.wait_handle = [];
    end
        
    try
        notify(obj,'fit_updated');    
    catch ME
        getReport(ME)
    end
    notify(obj,'fit_completed');    
end

