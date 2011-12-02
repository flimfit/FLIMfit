function load_segmentation(obj,folder)

    folder = ensure_trailing_slash(folder);

    d = obj.data_series_controller.data_series;
    
    obj.mask = zeros([d.height d.width d.n_datasets],'uint8');
    
    for i=1:d.n_datasets

        matching_files = dir([folder '*' d.names{i} '*.tif']);
        
        if ~isempty(matching_files)
            obj.mask(:,:,i) = uint8(imread([folder filesep matching_files(1).name]));
        end
                
    end
    
    obj.update_display();

end