function load_single_segmentation(obj,file)

    mask = uint8(imread(file));
    d = obj.data_series_controller.data_series;
    
    obj.mask = repmat(mask,[1 1 d.n_datasets]);

    obj.update_display();
end