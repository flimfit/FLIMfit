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


    if ishandleandvalid(obj.progress_bar)
        obj.progress_bar.StatusMessage = 'Processing Fit Results...';
        obj.progress_bar.Indeterminate = true;
    end
    
    r = obj.fit_result;
    d = obj.data_series;
    
    % Get timing information
    r.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(r.t_exec)]);
        
    obj.fit_result.smoothing = (2*d.binning+1)^2;
            
    results = ff_Controller(obj.dll_id,'GetFitResults');
    [summary, stats] = ff_FitResults(results,'GetStats');
    
    keep = true(size(obj.datasets));
    idx = r.n_results + 1;
    % Get results for each image
    for  i = 1:length(obj.datasets)
        
        im = obj.datasets(i);
                            
        region_sel = (summary.image == (im-1) & summary.size > 0);
        
        if sum(region_sel) > 0
            region_size_sel = summary.size(region_sel);
            regions_sel     = summary.regions(region_sel);
            iterations_sel  = summary.iterations(region_sel);
            success_sel     = summary.success(region_sel);

            stats_sel = stats(:,:,region_sel);

            stats_sel = permute(stats_sel,[2 3 1]);

            names = {'mean','w_mean','std','w_std','median','q1','q2','pct_01','pct_99','err_l','err_u'};

            r.set_results(idx,obj.dll_id,im,regions_sel,region_size_sel,success_sel,iterations_sel,stats_sel,names);
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
        md.(fields{i}) = f(r.image);
    end
    obj.fit_result.metadata = md;

    r.names = [r.names d.names(obj.datasets)];

    obj.result_objs(end+1) = results;
    
    obj.progress_bar = [];
    
end