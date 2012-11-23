function [data, column_headers] = get_param_list(obj)

    f = obj.fit_result;
    p = obj.fit_params; 
    
    if obj.bin
        datasets = 1;
    else
        datasets = obj.datasets;
    end
    
    % Column Headers
    % -------------------
    if p.global_fitting == 0 && ~obj.bin
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
        mean = f.region_mean{i};

        success = f.success{i};
        iterations = f.iterations{i};
        pixels = f.region_size{i};

        col = [im; double(regions); success; iterations; double(pixels); double(mean)]; 

        data = [data col];
    end
 end
