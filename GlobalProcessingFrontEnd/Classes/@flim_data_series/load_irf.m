function load_irf(obj,file,load_as_image)

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

    global profile;
    
    [path,name,ext] = fileparts(file);
    if strcmp(ext,'.xml')
       
        marshal_object(file,'flim_data_series',obj);
   
    else

        if strcmp(obj.mode,'TCSPC')
            channel = obj.request_channels(obj.polarisation_resolved);
        else
            channel = 1;
        end

        if nargin < 3
            load_as_image = false;
        end

        [t_irf,irf_image_data] = load_flim_file(file,channel);    
        irf_image_data = double(irf_image_data);

        % Sum over pixels
        s = size(irf_image_data);
        if length(s) == 3
            irf = reshape(irf_image_data,[s(1) s(2)*s(3)]);
            irf = mean(irf,2);
        elseif length(s) == 4
            irf = reshape(irf_image_data,[s(1) s(2) s(3)*s(4)]);
            irf = mean(irf,3);
        else
            irf = irf_image_data;
        end

        % export may be in ns not ps.
        if max(t_irf) < 300
           t_irf = t_irf * 1000; 
        end

        if load_as_image
            irf_image_data = obj.smooth_flim_data(irf_image_data,7);
            obj.image_irf = irf_image_data;
            obj.has_image_irf = true;
        else
            obj.has_image_irf = false;
        end


        obj.t_irf = t_irf(:);
        obj.irf = irf;
        obj.irf_name = 'irf';


        
    end

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    if profile.Data.Automatically_Estimate_IRF_Background
        obj.estimate_irf_background();
    end
    
    obj.compute_tr_irf();
    obj.compute_tr_data();
    
    notify(obj,'data_updated');

    
end