function update_progress(obj,~,~)

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

    
    p = obj.fit_params;

    group = zeros(1,p.n_thread);
    n_completed = zeros(1,p.n_thread);
    iter = zeros(1,p.n_thread);
    chi2 = zeros(1,p.n_thread);
    progress = 0.0;
    
    [finished, obj.progress_cur_group, obj.progress_n_completed, obj.progress_iter, obj.progress_chi2, obj.progress] ...
     = calllib(obj.lib_name,'FLIMGetFitStatus', obj.dll_id, group, n_completed, iter, chi2, progress); 
    
    if finished
        obj.get_return_data();
        if obj.fit_round > obj.n_rounds || ~obj.fit_in_progress
            obj.fit_in_progress = false;
            stop(obj.fit_timer);
            delete(obj.fit_timer);
            notify(obj,'fit_completed');
        else
            obj.fit();
        end
    else
        notify(obj,'progress_update');
    end
end