function get_return_data(obj)

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


    r = obj.fit_result;
    d = obj.data_series;
    
    % Get timing information
    r.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(r.t_exec)]);
        
  
    obj.fit_result.smoothing = (2*d.binning+1)^2;
    
        
    % Get param names
    p_n_output = libpointer('int32Ptr',0);
    ptr = calllib(obj.lib_name,'GetOutputParamNames',obj.dll_id, p_n_output);
        
    n_output = p_n_output.Value;
    param_names = cell(1,n_output);
    for i=1:n_output
        param_names(i) = ptr.Value;
        ptr = ptr + 1;
    end

    r.set_param_names(param_names);

    
    n_regions_total = calllib(obj.lib_name,'GetTotalNumOutputRegions',obj.dll_id);

    
    % Setup memory to retrieve data
    p_n_regions = libpointer('int32Ptr',0);
    p_image = libpointer('int32Ptr',zeros(1,n_regions_total)); 
    p_region = libpointer('int32Ptr',zeros(1,n_regions_total)); 
    p_region_size = libpointer('int32Ptr',zeros(1,n_regions_total)); 
    p_success = libpointer('singlePtr',zeros(1,n_regions_total)); 
    p_iterations = libpointer('int32Ptr',zeros(1,n_regions_total)); 
    
    
    n_stats = 11;
    
    p_stats = libpointer('singlePtr',zeros(n_stats,n_output,n_regions_total));
    

    
    err = calllib(obj.lib_name,'GetImageStats',obj.dll_id, p_n_regions, p_image, ...
                      p_region, p_region_size, p_success, p_iterations, p_stats);
    
                  
    region_size = double(p_region_size.Value);
    regions = double(p_region.Value);
    image = double(p_image.Value);
    iterations = double(p_iterations.Value);
    success = double(p_success.Value);
    stats = reshape(double(p_stats.Value),[n_stats,n_output,n_regions_total]);
                  
    
                                    
    keep = true(size(obj.datasets));
    idx = 1;
    % Get results for each image
    for  i = 1:length(obj.datasets)
        
        im = obj.datasets(i);
                            
        region_sel = (image == (im-1) & region_size > 0);
        
        if sum(region_sel) > 0
            region_size_sel = region_size(region_sel);
            regions_sel     = regions(region_sel);
            iterations_sel  = iterations(region_sel);
            success_sel     = success(region_sel);

            stats_sel = stats(:,:,region_sel);

            stats_sel = permute(stats_sel,[2 3 1]);

            names = {'mean','w_mean','std','w_std','median','q1','q2','pct_01','pct_99','err_l','err_u'};

            r.set_results(idx,im,regions_sel,region_size_sel,success_sel,iterations_sel,stats_sel,names);
            idx = idx+1;
        else
            keep(i) = false;
        end
        
    end
    
    obj.datasets = obj.datasets(keep);
    
    % Get metadata for the datasetes we've just fit
    md = obj.data_series.metadata;
    fields = fieldnames(md);
    for i=1:length(fields)
        f = md.(fields{i});
        md.(fields{i}) = f(obj.datasets);
    end
    
    obj.fit_result.metadata = md;
    
    function data = reshape_return(data,sel)

        
    end
    
end