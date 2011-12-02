function save_raw_images(obj,folder)
    
    folder = ensure_trailing_slash(folder);

    f = obj.fit_result;
    param_list = f.fit_param_list;
    
    for i=1:f.n_results
        for j=1:length(param_list)
           data = f.fit_param(j,i);
           im_name = [folder f.names{i} ' ' param_list{j} '.tif'];
           imwrite(data/max(data(:)),im_name);
        end
    end
end