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


classdef flim_fit_result_hdf5 < flim_fit_result
    
    properties
        file;
        result_info;
    end
    
   
methods
    
    function obj = flim_fit_result_hdf5(file)
       
        obj.smoothing = 0;
        
        obj.file = file;
        obj.width = h5readatt(file,'/results/','Width');
        obj.height = h5readatt(file,'/results/','Height');
        
        obj.result_info = h5info(file,'/results/'); 
        obj.n_results = length(obj.result_info.Groups);
        for i=1:length(obj.result_info.Datasets)
            obj.names{i} = obj.result_info.Groups(i).Attributes(1).Value;
        end
        
        param_info = h5info(file,'/results/image 1/');
        for i=1:length(param_info.Datasets)
            name = param_info.Datasets(i).Name;
            param_root = ['/results/image 1/' name];
            idx = h5readatt(file,param_root,'Index');
            param_name{idx} = name;
            group_idx(idx) = h5readatt(file,param_root,'GroupIndex');
        end
                
        obj.set_param_names(param_name,group_idx);
        
        stat_info = h5info(file,'/stats/');
        
        for i=1:length(stat_info.Datasets)
            stat_name = stat_info.Datasets(i).Name;
            stat_root = ['/stats/' stat_name];
            obj.region_stats(1).(stat_name) = h5_readtable(file,stat_root);
            this_idx = h5readatt(file,stat_root,'Index');
            idx(this_idx) = i; 
            obj.stat_names{i} = stat_name;
        end
        obj.region_stats = orderfields(obj.region_stats,idx);
        obj.stat_names = obj.stat_names(idx);

        % Get metadata for the datasets we've just fit
        obj.metadata = h5_readtable(file,'/metadata/');
        
        obj.update_default_lims();
        
        pct_01 = table2array(obj.region_stats.pct_01);
        pct_99 = table2array(obj.region_stats.pct_99);  
        
        pct_01 = pct_01(:,6:end);
        pct_99 = pct_99(:,6:end);
        
        lims(:,1) = nanmin(pct_01,[],1);
        lims(:,2) = nanmax(pct_99,[],1);
        obj.default_lims = lims;
            
    end
            
    function [param_data, mask] = get_image_result_indexing(obj,dataset,param)
        param_data = h5read(obj.file,['/results/image ' num2str(dataset) '/' obj.params{param}]);
        mask = isfinite(param_data);
    end
        
end
    
end