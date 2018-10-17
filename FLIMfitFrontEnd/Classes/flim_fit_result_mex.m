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


classdef flim_fit_result_mex < flim_fit_result
    
    properties
       ptr; 
       datasets;
    end
    
   
methods
    
    function obj = flim_fit_result_mex(ptr, data_series, datasets)

        obj.datasets = reshape(datasets,[length(datasets),1]);
        obj.smoothing = (2*data_series.binning+1)^2;
        
        obj.width = data_series.width;
        obj.height = data_series.height;

        obj.ptr = ptr;
        [summary, stats] = ff_FitResults(obj.ptr,'GetStats');

        [param_names, param_groups] = ff_FitResults(obj.ptr,'GetOutputParamNames'); 
        obj.set_param_names(param_names, param_groups);

        names = {'mean','w_mean','std','w_std','median','q1','q2','pct_01','pct_99','err_l','err_u'};
        obj.stat_names = names;
        
        % Translate subset image -> real image
        summary.image = obj.datasets(summary.image + 1,1);
        
        initial_table = struct2table(summary);
            
        obj.region_stats = struct();
        for i=1:size(stats,1)
            statsi = stats(i,:,:);
            statsi = permute(statsi,[3 2 1]);
            statsi = array2table(statsi,'VariableNames',obj.params);
            obj.region_stats.(names{i}) = [initial_table statsi];
        end

        %{
        keep = true(size(obj.datasets));
        idx = 1;
        % Get results for each image
        for i = 1:length(obj.datasets)
            im = obj.datasets(i);

            region_sel = (summary.image == (i-1) & summary.size > 0);
            
            if sum(region_sel) > 0
                region_size_sel = summary.size(region_sel);
                regions_sel     = summary.region(region_sel);
                iterations_sel  = summary.iterations(region_sel);
                success_sel     = summary.success(region_sel);

                stats_sel = stats(:,:,region_sel);
                stats_sel = permute(stats_sel,[2 3 1]);

                obj.set_results(idx,im,regions_sel,region_size_sel,success_sel,iterations_sel,stats_sel,names);
                idx = idx+1;
            else
                keep(i) = false;
            end
        end
        obj.datasets = obj.datasets(keep);
        %}

        % Get metadata for the datasets we've just fit
        obj.metadata = data_series.metadata(obj.datasets,:);
        obj.names = data_series.names(obj.datasets);
        obj.n_results = length(obj.datasets);
        
        obj.update_default_lims();
        
        %{
        pct_01 = table2array(obj.region_stats.pct_01);
        pct_99 = table2array(obj.region_stats.pct_99);
        
        pct_01 = pct_01(:,6:end)';
        pct_99 = pct_99(:,6:end)';
        
        lims(:,1) = nanmin(obj.default_lims(:,1),nanmin(pct_01,[],2));
        lims(:,2) = nanmax(obj.default_lims(:,2),nanmax(pct_99,[],2));
        obj.default_lims = lims;
        %}
            
    end
            
    function [param_data, mask] = get_image_result_indexing(obj,dataset,param)
        [param_data, mask] = ff_FitResults(obj.ptr,'GetParameterImage', dataset, param);
    end
        
end
    
end