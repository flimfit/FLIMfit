function load_segmentation(obj,folder)

    if folder==0
        return
    end

    folder = ensure_trailing_slash(folder);

    d = obj.data_series_controller.data_series;
    
    str = {'Replace' 'AND' 'OR' 'NAND' 'Acceptor'};
    [choice,ok] = listdlg('PromptString','How would you like to combine the selected files with the current mask?',...
                    'SelectionMode','single',...
                    'ListString',str);
    
    if ~ok
        return
    end
    
    new_sz = [d.height*d.width d.n_datasets];
    
    if isempty(obj.mask)
        new_mask = zeros(new_sz);
    else
        new_mask = reshape(obj.mask,new_sz);
    end
    
    for i=1:d.n_datasets

        matching_files = dir([folder '*' d.names{i} '*.tif*']);
        
        if ~isempty(matching_files)
            mask = uint8(imread([folder matching_files(1).name]));
        else
            mask = ones([d.height d.width],'uint8');
        end

        switch choice
            case 1
                new_mask(:,i) = mask(:);
            case 2
                mask = mask == 0;
                new_mask(mask(:),i) = 0;
            case 3
                mask = mask > 0;
                new_mask(mask(:),i) = 1;
            case 4
                mask = mask > 0;
                new_mask(mask(:),i) = 0;  
            case 5
                old_mask = reshape(new_mask(:,i),[d.height d.width]);
                [z,n]=bwlabel(old_mask>0,4);
                for j=1:n
                   
                    m = (z == j);
                    acc = sum(mask(m));
                    don = sum(m(:));
                    if acc/don < 0.3
                        z(m) = 0;
                    end
                    
                end
                
                z = z > 0;
                new_mask(:,i) = z(:);

                
        end
                
    end
    
    obj.mask = reshape(new_mask,[d.height d.width d.n_datasets]);
    obj.filtered_mask = obj.mask;
    
    obj.update_display();

end