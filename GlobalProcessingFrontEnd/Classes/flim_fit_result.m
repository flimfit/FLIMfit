classdef flim_fit_result < handle
   
    
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

    
    properties
        
        regions;
        region_size;
        image_size;
       
        
        image;
        image_stats;
        region_stats;
        
        n_regions;
        
        chi2;
        ierr;
        iterations;
        success;
        
        names;
        metadata;
        
        n_results = 0;
        
        intensity_idx;
        
        smoothing = 1;
        
        params = {};
        latex_params = {};
        
        default_lims = []; 
        
        width;
        height;
        
        stat_names = {};
    end
    
    properties(SetObservable = true)
        cur_lims;
    end
    
    properties(Transient = true)
        has_grid;
        grid;
        binned;
        t_exec;
        job;
        ready = true;
        is_temp = true;
    end
    
    
   
    
    methods
        
        function obj = flim_fit_result()
        end

        
        function set_param_names(obj,params)
            obj.params = params;
            obj.intensity_idx = find(strcmp(params,'I'));            
            obj.default_lims = NaN(length(params),2);
            
            for i=1:length(params)
                lp = params{i};
                lp = strrep(lp,'mean_tau','mean tau');
                lp = strrep(lp,'w_mean','weighted mean');
                lp = strrep(lp,'r_ss','r_{ss}');

                obj.latex_params{i} = lp;
            end
                           
        end
            
        function set_results(obj,idx,im,regions,region_size,success,iterations,stats,names)
            
            region_size = double(region_size);
            stats = double(stats);
            
            
            % Set statistics by region
            obj.regions{idx} = regions;
            obj.image(idx) = im;
            obj.region_size{idx} = region_size;
            
            for i=1:length(names)
                r_stats.(names{i}) = stats(:,:,i);
            end
            
            obj.region_stats{idx} = r_stats;

            % Calculate image wise statistics
            [M,S] = combine_stats(r_stats.mean,r_stats.std,region_size);
            [w_M,w_S,N] = combine_stats(r_stats.w_mean,r_stats.w_std,region_size);
            
            obj.image_size{idx} = N;
            
            obj.image_stats{idx}.mean = M; 
            obj.image_stats{idx}.std = S;
            
            obj.image_stats{idx}.w_mean = w_M; 
            obj.image_stats{idx}.w_std = w_S;
            
            stats_to_average = {'median','q1','q2','pct_01','pct_99','err_l','err_u'};
            
            for i=1:length(stats_to_average)
                obj.image_stats{idx}.(stats_to_average{i}) = nanmean(r_stats.(stats_to_average{i}),2);
            end
            
            obj.success{idx} = double(success) * 100;
            obj.iterations{idx} = double(iterations);
            
            lims(:,1) = nanmin(obj.default_lims(:,1),nanmin(r_stats.pct_01,[],2));
            lims(:,2) = nanmax(obj.default_lims(:,2),nanmax(r_stats.pct_99,[],2));
            obj.default_lims = lims;  
            
            obj.n_results = obj.n_results + 1;
            
            obj.stat_names = names;
            
        end
        
        function lims = get_default_lims(obj,param)
            lims = obj.default_lims(param,:);
            lims(1) = sd_round(lims(1),3,3); % round down to 3sf
            lims(2) = sd_round(lims(2),3,2); % round up to 3sf
        end

        
        function set_metadata(obj,name,r,data)
            if length(r) == 1
                obj.metadata{r}.(name) = data;
            elseif iscell(im)
                for i=1:length(r)
                    obj.metadata{r(i)} = data{i};
                end
            else
                for i=1:length(r)
                    obj.metadata{r(i)} = im;
                end
            end 
        end
       
        
        function params = fit_param_list(obj)
            params = obj.params;
        end
        
        function set_stats_from_table(obj,table_data)
            
            stats_names = {'mean','w_mean','std','w_std','median','q1','q2','pct_01','pct_99','err_l','err_u'};
            
            [rows, cols] = size(table_data);
            table_stats_names = table_data(7:rows,1);
            
            statnames = cell(1,numel(table_stats_names));
            param_names = cell(1,numel(table_stats_names));
            for k = 1 : numel(table_stats_names)
                curstr = char(table_stats_names(k));
                sepstart = strfind(curstr,' - ');
                A = curstr(1:sepstart-1);
                B = curstr(sepstart+3:length(curstr));
                statnames(k) = cellstr(A);
                param_names(k) = cellstr(B);                
            end
            
%            statnames = unique(statnames,'legacy');
%            param_names = unique(param_names,'legacy');            

            z = 0;
            while true
                z=z+1;                
                if strcmp( char(statnames(z)),char(statnames(1)) )
                    unique_param_names(z) = param_names(z);
                else
                    break;
                end;                
            end
            
            n_params = numel(unique_param_names);
            
            filenameS =     table_data(1,2:cols);
            im_groupS =     table_data(2,2:cols);
            regionS =       table_data(3,2:cols);
            successS =      table_data(4,2:cols);
            iterationS =    table_data(5,2:cols);
            pixelS =        table_data(6,2:cols);                        
            
            n_stats = numel(stats_names);
            n_data = cols-1;            

            for d = 1 : n_data
                Dd = struct();
                for s = 1 : n_stats
                    %Dd.(stats_names{s}) = rand(1,n_params);
                    strtind = 7 + n_params*(s-1);
                    endind = strtind + n_params - 1;
                    Dd.(stats_names{s}) = cell2mat(table_data(strtind:endind,d+1))';
                end
                data{d} = Dd;
            end
            
            % need to leave only columns corresponding to the selected FOVs..            
            z = 0;
            for d = 1 : n_data
                for sd = 1 : numel(obj.metadata.FileName) 
                    if strcmp(filenameS{d},obj.metadata.FileName{sd})
                        z = z + 1;
                        data_cropped(z) = data(d);
                        imagesizes{z} = pixelS{d}; % BTW
                        succcsesss{z} = successS{d};
                    end
                end
            end
            
            obj.image_size = imagesizes;
            obj.region_size = obj.image_size;
            obj.success = succcsesss; 
            
            n_data = numel(obj.image_size); %re-assign "n_data" :)
            
            obj.image_stats = data_cropped;
            obj.region_stats = data_cropped;
            
            lims(:,1) = ones(n_params,1)*Inf;
            lims(:,2) = ones(n_params,1)*(-Inf);

            for p = 1 : n_params
                for d = 1 : n_data
                    lims(p,1) = nanmin( lims(p,1),obj.image_stats{d}.pct_01(p) );
                    lims(p,2) = nanmax( lims(p,2),obj.image_stats{d}.pct_99(p) );
                end
            end
            obj.default_lims = lims;
            obj.stat_names = stats_names;
            
            obj.regions = cell(1,n_data);
            for d=1:n_data, obj.regions{d} = 1; end;
            
            obj.smoothing = 9;
            
            str = obj.params;
            obj.latex_params = strrep(str,'_',' ');
            
        end
        
        
        %{
        function img = get_image(obj,dataset,param)
           
            img = nan;
            
            if dataset > length(obj.names) || dataset < 1
                return;
            end
            
            if ~obj.use_memory_mapping && isfield(obj.images{dataset},param)
                img = obj.images{dataset}.(param);
            else
               
                path = ['/' obj.names{dataset} '/' param];
                if exist(obj.file,'file')
                    try 
                        img = h5read(obj.file,path);
                    catch e %#ok
                        img = nan;
                    end
                else
                    img = nan;
                end
            end
            
        end
        
        
        function save(obj,file)
           
            if exist(file,'file')
                delete(file);
            end
                
            if obj.use_memory_mapping
                
                copyfile(obj.file,file);
                
            else

                for i=1:obj.n_results

                    im = obj.images{i};
                    fields = fieldnames(im);

                    for j=1:length(fields)
                        dataset_name = ['/' obj.names{i} '/' fields{j}];
                        h5create(file,dataset_name,size(im.(fields{j})));
                        h5write(file,dataset_name,im.(fields{j}));
                    end

                end

            end;
        end

        function load(obj,file)

            
            info = h5info(file);
            groups = info.Groups;
            obj.n_results = length(groups);
            
            if obj.use_memory_mapping
                
                obj.file = file;
                obj.is_temp = false;
                
                for i=1:n_result
                    obj.names{i} = groups(i).Name;
                end
                
                datasets = groups.Datasets;
                for j=1:length(datasets)
                    obj.params{end+1} = datasets(j).Name;
                end
                
            else

                obj.images = cell(1,obj.n_results);
                obj.names = cell(1,obj.n_results);
                for i=1:n_result
                    obj.names{i} = groups(i).Name;
                    datasets = groups.Datasets;
                    obj.images{i} = struct();
                    for j=1:length(datasets)
                        obj.images{i}.(datasets(j).Name) = h5read(file,[ '/' obj.names{i} '/' datasets(j).Name]);
                    end
                end
                
            end
            
            
        end
%}
        
        
    end
    
    
end