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

    
    if obj.fit_in_progress

        p = obj.fit_params;

        [progress, n_completed, cur_group, iter, chi2] = obj.dll_interface.get_progress();

        if ~isempty(obj.wait_handle)
            if progress > 0
                obj.wait_handle.Indeterminate = 'off';
                obj.wait_handle.Value = progress;
            end
        end

        table_data = [double((1:p.n_thread)); double(n_completed); ...
                      double(cur_group); double(iter); double(chi2)];

        set(obj.progress_table,'Data',table_data);
    end
    
end