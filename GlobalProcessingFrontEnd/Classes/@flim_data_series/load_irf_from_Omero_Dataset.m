function load_irf_from_Omero_Dataset(obj,session,dataset,load_as_image)

                imageList = dataset.linkedImageList;
                %       
                if 0==imageList.size()
                    errordlg(['Dataset ' pName ' have no images'])
                    return;
                end;                                    
                %        
                NoOfFiles = imageList.size();
                
                filenames = [];
                for k = 1:NoOfFiles,                       
                    iName = char(java.lang.String(imageList.get(k-1).getName().getValue()));
                    filenames{k} = iName;
                end
                
                filenames = sort_nat(filenames);
                
                store = session.createRawPixelsStore(); 

                h = []; %sizeX
                w = []; %sizeY
                im_data = [];

                for f = 1:NoOfFiles
                                        
                    fname = cellstr(filenames{f});
                    [~,name] = fileparts(char(fname));
                    tokens = regexp(name,'INT\_(\d+)','tokens');
                    if ~isempty(tokens)
                        t_int(f) = str2double(tokens{1});
                    end
                    
                    tokens = regexp(name,'(?:^|\s)T\_(\d+)','tokens');
                    if ~isempty(tokens)
                        delays(f) = str2double(tokens{1});
                    else
                        name = name(end-4:end);      %last 6 chars contains delay 
                        delays(f) = str2double(name);                       
                    end
                    % read CORRESPONDING image                    
                    for f1 = 1:NoOfFiles                        
                        fname1 = char(java.lang.String(imageList.get(f1-1).getName().getValue()));
                        if strcmp(fname1,char(fname))                    
                            break;
                        end
                    end % f1 is the index of corresponding image
                           image = imageList.get(f1-1);
                           pixelsList = image.copyPixels();    
                           pixels = pixelsList.get(0);
                           pixelsId = pixels.getId().getValue();
                           store.setPixelsId(pixelsId, false);                                           
                           %
                           if isempty(h)
                                sizeX = pixels.getSizeX().getValue();
                                sizeY = pixels.getSizeY().getValue();
                                h = sizeX;
                                w = sizeY;
                                im_data = zeros(NoOfFiles,w,h);
                           end
                           %
                         rawPlane = store.getPlane(0, 0, 0);   
                         plane = toMatrix(rawPlane, pixels); 
                         im_data(f,:,:) = plane';                                            
                    end
    
                store.close();
                
                if min(im_data(:)) > 32500
                    im_data = im_data - 32768;    % clear the sign bit which is set by labview
                end                
                
    t_irf = delays;
                                
    %
    irf_image_data = double(im_data);
    
    % Sum over pixels
    s = size(irf_image_data);
    if length(s) == 3
        irf = reshape(irf_image_data,[s(1) s(2)*s(3)]);
        irf = mean(irf,2);
    elseif length(s) == 4
        irf = reshape(irf_image_data,[s(1) s(2) s(3)*s(4)]);
        irf = mean(irf,3);
    else
        irf = irf_image_data;
    end
    
    % export may be in ns not ps.
    if max(t_irf) < 300
       t_irf = t_irf * 1000; 
    end
    
    if load_as_image
        irf_image_data = obj.smooth_flim_data(irf_image_data,7);
        obj.image_irf = irf_image_data;
        obj.has_image_irf = true;
    else
        obj.has_image_irf = false;
    end
        
    obj.t_irf = t_irf(:);
    obj.irf = irf;
    obj.irf_name = 'irf';

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    obj.estimate_irf_background();
    
    obj.compute_tr_irf();
    obj.compute_tr_data();
    
    notify(obj,'data_updated');
    
end