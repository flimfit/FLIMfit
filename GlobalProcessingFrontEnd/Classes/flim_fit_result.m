classdef flim_fit_result < handle
   
    properties
        
        regions;
        region_size;
        image_size;
        image_mean;
        image_std;
        region_mean;
        region_std;
        
        images;
        image_stats;
        region_stats;
        
        n_regions;
        
        chi2;
        ierr;
        iterations;
        success;
        
        names;
        metadata;
        
        n_results;
        
        intensity_idx;
        
        use_memory_mapping = true;
        file = [];
        
        smoothing = 1;
        
        params = {};
        
        default_lims; 
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
        
        function init(obj,n_results,memory_mapping)
        
            if nargin < 3
                memory_mapping = false;
            end
            
            obj.n_results = n_results;
            
            obj.default_lims = [];
            
            obj.n_regions = zeros(1, n_results);
            
            if obj.use_memory_mapping
               
                obj.file = global_tempname;
                
                if exist(obj.file,'file')
                    delete(obj.file)
                end
                
            end
            
            obj.use_memory_mapping = memory_mapping;
            
        end
        
        function delete(obj)
            if obj.use_memory_mapping && exist(obj.file,'file') && obj.is_temp
                delete(obj.file)
            end
        end
 
        function set_param_names(obj,params)
            obj.params = params;
            obj.intensity_idx = find(strcmp(params,'I'));
            
            obj.default_lims = NaN(length(params),2);
            
        end
        
        function set_results(obj,idx,regions,region_size,success,iterations,param_mean,param_std,param_01,param_99)
            
            [M,S,N] = combine_stats(double(param_mean),double(param_std),double(region_size));
            
            obj.image_mean{idx} = M; 
            obj.image_size{idx} = N; 
            obj.image_std{idx} = S;
            
            obj.regions{idx} = regions;
            obj.region_size{idx} = region_size;
            obj.region_mean{idx} = param_mean;
            obj.region_std{idx} = param_std;
            
            obj.success{idx} = double(success) * 100;
            obj.iterations{idx} = double(iterations);
            
            lims(:,1) = nanmin(obj.default_lims(:,1),param_01);
            lims(:,2) = nanmax(obj.default_lims(:,2),param_99);
            obj.default_lims = lims;  
            
        end
        
        function lims = get_default_lims(obj,param)
            lims = obj.default_lims(param,:);
            lims(1) = sd_round(lims(1),3,3); % round down to 3sf
            lims(2) = sd_round(lims(2),3,2); % round up to 3sf
        end
        
        function lims = get_cur_lims(obj,param)
            
            if ischar(param)
                param_idx = strcmp(obj.params,param);
                param = find(param_idx);
            end
            
            lims = obj.cur_lims(param,:);
            lims(1) = sd_round(lims(1),3,3); % round down to 3sf
            lims(2) = sd_round(lims(2),3,2); % round up to 3sf
        end
        
        function lims = set_cur_lims(obj,param,lims)
            obj.cur_lims(param,:) = lims;
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
        
        function n_results = get_n_results(obj)
            n_results = length(obj.images);
        end
        
        function params = fit_param_list(obj)
            params = obj.params;
        end
        
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

        
        
    end
    
    
end