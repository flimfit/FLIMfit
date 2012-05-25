function load_single_segmentation(obj,file)

    str = {'Replace' 'AND' 'OR' 'NAND'};
    [choice,ok] = listdlg('PromptString','How would you like to combine the selected files with the current mask?',...
                    'SelectionMode','single',...
                    'ListString',str);

    if ~ok
        return
    end
    
    d = obj.data_series_controller.data_series;
    
    mask = uint8(imread(file));
    mask = repmat(mask,[1 1 d.n_datasets]);

    switch choice
        case 1
            obj.mask = mask;
        case 2
            mask = mask == 0;
            obj.mask(mask) = 0;
        case 3
            mask = mask > 0;
            obj.mask(mask) = 1;
        case 4
            mask = mask > 0;
            obj.mask(mask) = 0;        
    end
    
    obj.update_display();
end