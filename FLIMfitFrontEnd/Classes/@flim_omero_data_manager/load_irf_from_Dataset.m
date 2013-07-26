function load_irf_from_Dataset(obj,data_series,dataset,load_as_image)


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

  

    [t_irf im_data] = obj.load_FLIM_data_from_Dataset(dataset);                                
    %
    irf_image_data = double(im_data);
    
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
        irf_image_data = data_series.smooth_flim_data(irf_image_data,7);
        data_series.image_irf = irf_image_data;
        data_series.has_image_irf = true;
    else
        data_series.has_image_irf = false;
    end
        
    data_series.t_irf = t_irf(:);
    data_series.irf = irf;
    data_series.irf_name = 'irf';

    data_series.t_irf_min = min(data_series.t_irf);
    data_series.t_irf_max = max(data_series.t_irf);
    
    data_series.estimate_irf_background();
    
    data_series.compute_tr_irf();
    data_series.compute_tr_data();
    
    notify(data_series,'data_updated');
    
end