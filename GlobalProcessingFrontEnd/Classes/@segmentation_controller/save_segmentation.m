function save_segmentation(obj,folder)

    folder = ensure_trailing_slash(folder);
    
    if isempty(obj.mask)
        return
    end
    
    d = obj.data_series_controller.data_series;
    
    for i=1:d.n_datasets
       
        file = [folder d.names{i} ' segmentation.tif'];
        imwrite(obj.mask(:,:,i),file);
        
    end

end