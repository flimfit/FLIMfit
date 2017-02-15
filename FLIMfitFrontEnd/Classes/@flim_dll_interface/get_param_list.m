function [data, column_headers] = get_param_list(obj)
    

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


    f = obj.fit_result;
    p = obj.fit_params; 
    
    if obj.bin
        datasets = 1;
    else
        datasets = obj.datasets;
    end
    
    % Column Headers
    % -------------------
    if p.global_scope == 0 && ~obj.bin
        column_headers = {'im_group'; 'region'; 'success %'; 'iterations'; 'pixels'};
    else
        column_headers = {'im_group'; 'region'; 'return code'; 'iterations'; 'pixels'};
    end
    
    im_names = f.fit_param_list();
    
    column_headers = [column_headers; im_names'];
    
    data = [];
    for i=1:length(f.regions)

        im = datasets(i);
        regions = f.regions{i};
        n_regions = length(regions);
        im = repmat(im,[1,n_regions]);
        mean = f.region_stats{i}.mean;

        success = f.success{i};
        iterations = f.iterations{i};
        pixels = f.region_size{i};

        col = [im; double(regions); success; iterations; double(pixels); double(mean)]; 

        data = [data col];
    end
 end
