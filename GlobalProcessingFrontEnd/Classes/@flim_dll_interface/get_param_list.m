function [data, column_headers] = get_param_list(obj)

    f = obj.fit_result;
    p = obj.fit_params; 
    %d = obj.data_series;
    
    %n_px = d.width * d.height;
    %n_im = n_group;
    %n_group = d.n_datasets;
    
    if obj.bin
        datasets = 1;
    else
        datasets = obj.datasets;
    end
    
    % Column Headers
    % -------------------
    if p.global_fitting == 0 && ~obj.bin
        column_headers = {'im_group'; 'region'; 'success %'; 'iterations'};
    else
        column_headers = {'im_group'; 'region'; 'return code'; 'iterations'};
    end
    
    im_names = f.fit_param_list();
    
    column_headers = [column_headers; im_names'];
    
    %{
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
    %}
    data = [];
    for i=1:length(f.regions)

        im = datasets(i);
        regions = f.regions{i};
        n_regions = length(regions);
        im = repmat(im,[1,n_regions]);
        mean = f.region_mean{i};

%            f.success
%            f.iter

        success = -1*ones(size(im));

        col = [im; double(regions); success; success; double(mean)]; 

        data = [data col];
    end
 end
