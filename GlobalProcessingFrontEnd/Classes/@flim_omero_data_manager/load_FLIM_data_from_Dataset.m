function [ delays, im_data ] = load_FLIM_data_from_Dataset(obj,dataset)

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
                
                store = obj.session.createRawPixelsStore(); 

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
                
end