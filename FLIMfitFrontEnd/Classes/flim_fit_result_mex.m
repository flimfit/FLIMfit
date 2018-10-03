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

        obj.datasets = datasets;
        obj.smoothing = (2*data_series.binning+1)^2;

        obj.ptr = ptr;
        [summary, stats] = ff_FitResults(obj.ptr,'GetStats');

        [param_names, param_groups] = ff_FitResults(obj.ptr,'GetOutputParamNames'); 
        obj.set_param_names(param_names, param_groups);

        names = {'mean','w_mean','std','w_std','median','q1','q2','pct_01','pct_99','err_l','err_u'};
        obj.stat_names = names;

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

        % Get metadata for the datasets we've just fit
        md = data_series.metadata;
        fields = fieldnames(md);
        for i=1:length(fields)
            f = md.(fields{i});
            md.(fields{i}) = f(obj.image);
        end
        obj.metadata = md;

        obj.names = data_series.names(obj.datasets);
    end
            
    function [param_data, mask] = get_image(obj,dataset,param,indexing)
        param_data = 0;
        mask = 0;

        if nargin < 4 || strcmp(indexing,'result')
            dataset = obj.image(dataset);
        end

        [~,idx] = find(obj.image == dataset); 

        if ~isempty(idx)
            [param_data, mask] = ff_FitResults(obj.ptr,'GetParameterImage', idx, param);
        end
    end
    
    %function delete(obj)
        %ff_FitResults(obj.ptr,'Clear');
        %ff_FitResults(obj.ptr,'Release');
    %end        
    
end
    
end