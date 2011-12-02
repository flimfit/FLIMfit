function [data, column_headers] = get_param_list(obj)

    f = obj.fit_result;
    p = obj.fit_params; 
    d = obj.data_series;
    
    n_px = d.width * d.height;
    n_group = sum(d.use);
    n_im = n_group;
   
    if obj.bin
        datasets = 1;
    else
        datasets = obj.datasets;
    end
    
    % Column Headers
    % -------------------
    if p.global_fitting == 0 && ~obj.bin
        column_headers = {'im_group' 'region' 'success %' 'iterations'};
    else
        column_headers = {'im_group' 'region' 'return code' 'iterations'};
    end
    
    im_names = f.fit_param_list();
    
    column_headers = [column_headers im_names];
    
    if obj.bin
        n_regions = obj.n_regions;		      
    else
                
        switch p.global_fitting
            case 0 %global_mode.pixel
                n_regions = ones([1 n_im]);
            case 1 %sglobal_mode.image
                n_regions = obj.n_regions;
            case 2 %global_mode.dataset
                n_regions = repmat(obj.n_regions,[1 n_im]);
        end
    end
    
    if obj.bin
        row = [0 0 f.ierr(1) f.iter(1)];
        for i=1:length(im_names)
            if isfield(f.region_stats{1}.(im_names{i}),'mean')
                im = f.region_stats{1}.(im_names{i}).mean;
                im = im(1);
            else
                im = 0;
            end
            row = [row im]; %#ok
        end
        
        data = row;
    else
        idx = 1;
        for g=1:n_group
            for r=1:f.n_regions(g)
                if p.global_fitting == 0
                    row = [g r f.success(g) f.iter(g)];
                else
                    row = [g r f.ierr(g) f.iter(g)];
                end
                for i=1:length(im_names)
                    if isfield(f.region_stats{g}.(im_names{i}),'mean')
                        im = f.region_stats{g}.(im_names{i}).mean;
                        im = im(r);
                    else
                        im = 0;
                    end
                    row = [row im]; %#ok
                end
                
                data(idx, :) = row; %#ok
                idx = idx+1;
            end
        end
    end
 end
