classdef flim_fit_result < handle
   
    properties
        images;
        image_stats;
        region_stats;
        
        n_regions;
        
        chi2;
        ierr;
        iter;
        success;
        
        names;
        metadata;
        
        n_results;
        
        use_memory_mapping = true;
        file = [];
        
        params = {};
    end
    
    properties(SetObservable = true)
        default_lims; 
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
            
            obj.images = cell(1,n_results);
            obj.image_stats = cell(1,n_results);
            obj.region_stats = cell(1,n_results);
            obj.metadata = cell(1,n_results);
            
            for i = 1:n_results
                obj.images{i} = struct();
                obj.image_stats{i} = struct();
                obj.region_stats{i} = struct();
                obj.metadata = struct();
            end
            
            obj.default_lims = struct();
            
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
       
 
        function set_image_split(obj,name,im,mask,intensity,r,default_lims,err)
            if nargin < 7
                default_lims = [];
            end
            if nargin < 8
                err = [];
            end
            s = size(im);
            n = size(im,3);
            if length(s) > 2
                s = s(1:end-1);
            else
                s = [1 1];
            end
            for i=1:n
                ix = im(:,:,i);
                obj.set_image([name '_' num2str(i)],ix,mask,intensity,r,default_lims);
                if ~isempty(err)
                    ex = err(:,:,i);
                    ex = reshape(ex,s);
                    if ~all(isnan(ex(:)))
                        obj.set_image([name '_' num2str(i) '_err'],ex,mask,intensity,r,default_lims);
                    end
                end
            end
        end
                
        function set_image(obj,name,im,mask,intensity,r,default_lims)
            if nargin == 7 && ~isempty(default_lims)
                obj.set_default_lims(name,default_lims);
            end                
            
            obj.write(r,name,im,mask,intensity);
             
        end
        
        function set_default_lims(obj,name,lims)
            obj.default_lims.(name) = lims;
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
        
        function write(obj,dataset,param,img,mask,intensity)
            
            img = single(img);
            
            if isempty(mask) || sum(mask(:)) == 0
              
                n_regions = 1;
                obj.n_regions(dataset) = 1;
                
                sel = ~isnan(img);
                timg = img(sel);
                tmask = ones(size(timg));
            else
                n_regions = max(mask(:));
                obj.n_regions(dataset) = n_regions;

                sel = mask>0 & ~isnan(img);
                timg = img(sel);
                tmask = mask(sel);
            end
            
            
            tintensity = intensity(sel);
            wtimg = timg .* tintensity / mean(tintensity);
            
            % Calculate image means
            
            img_mean = trimmean(timg,1);
            img_std = trimstd(timg,1);
            img_n = sum(tmask);
                        
            region_mean = zeros(1,n_regions);
            region_std = zeros(1,n_regions);
            region_n = zeros(1,n_regions);

            for i=1:n_regions
                if isempty(timg)
                    region_mean(i) = nan;
                    region_std(i) = nan;
                    region_n(i) = nan;
                else
                    td = timg(tmask==i);
                    region_mean(i) = trimmean(td,1);
                    region_std(i) = trimstd(double(td),1);
                    region_n(i) = length(td);
                end
            end
            
            % Calculate weighted means
            
            w_img_mean = trimmean(timg,1);
            w_img_std = trimstd(timg,1);
            w_img_n = sum(tmask);
                        
            w_region_mean = zeros(1,n_regions);
            w_region_std = zeros(1,n_regions);
            w_region_n = zeros(1,n_regions);

            for i=1:n_regions
                if isempty(wtimg)
                    w_region_mean(i) = nan;
                    w_region_std(i) = nan;
                    w_region_n(i) = nan;
                else
                    td = wtimg(tmask==i);
                    w_region_mean(i) = trimmean(td,1);
                    w_region_std(i) = trimstd(double(td),1);
                    w_region_n(i) = length(td);
                end
            end
            
            stats = struct('mean',img_mean,'std',img_std,'w_mean',w_img_mean,'w_std',w_img_std,'n',img_n);
            obj.image_stats{dataset}.(param) = stats;
            
            stats = struct('mean',region_mean,'std',region_std,'w_mean',region_mean,'w_std',region_std,'n',region_n);
            obj.region_stats{dataset}.(param) = stats;
            
            if ~any(strcmp(obj.params,param))
                obj.params = [obj.params param];
            end
            
            if ~obj.use_memory_mapping
                obj.images{dataset}.(param) = single(img);
                
            else
                path = ['/' obj.names{dataset} '/' param];
                h5create_direct(obj.file,path,size(img),'ChunkSize',size(img),'Deflate',0);
                h5write(obj.file,path,img);
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