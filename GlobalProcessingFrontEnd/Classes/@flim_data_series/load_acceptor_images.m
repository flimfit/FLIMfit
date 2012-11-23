function load_acceptor_images(obj,path)

    path = ensure_trailing_slash(path);

    obj.acceptor = zeros([obj.height obj.width obj.n_datasets]);
    
    items =  dir([path '*background*']);
    
        
    bg = 0;
    if ~isempty(items)
        item = items(1);
        if item.isdir
            items =  dir([path item.name '\']);
            bg = load_flim([path item.name '\'],items);
        else
            bg = load_flim(path,items);
        end
    end

    h = waitbar(0,'Loading Acceptor Images...');
    for i=1:obj.n_datasets
       
        items =  dir([path '*' obj.names{i} '*']);
        
        if ~isempty(items)
           
            item = items(1);
            
            im = [];
            
            if item.isdir
                items =  dir([path item.name '\']);
                im = load_flim([path item.name '\'],items);
            else
                im = load_flim(path,items);
            end
          
            
            if ~isempty(im)
                im = medfilt2(im,[7 7]);
                obj.acceptor(:,:,i) = im-bg;
            end
                
    
        end
        waitbar(i/obj.n_datasets,h);
    end
    close(h);
    
    function im = load_flim(path,items)
       
        im = [];
        
        for j=1:length(items)
           
            [~,~,ext] = fileparts(items(j).name);
            
            if strcmp(ext,'.tif')
                im = [path items(j).name];
                break;
            end
                        
        end
        
        if ~isempty(im)
            [~,data] = load_flim_file(im);

            im = squeeze(mean(mean(data,1),2));
        end
        
    end

end