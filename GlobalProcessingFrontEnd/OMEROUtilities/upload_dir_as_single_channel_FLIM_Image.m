        function new_imageId = upload_dir_as_single_channel_FLIM_Image(session,Dataset,folder,extension,image_description,pixeltype)
            %
            new_imageId = [];
            %            
            strings  = split(filesep,folder);
            %
            %%%%%%%%%%%%%%%%%%%%%%%%% that works only for tiffs....                         
                    files = dir([folder filesep '*.' extension]);
                    num_files = length(files);
                    if 0==num_files
                        errordlg('No suitable files in the directory');
                        return;
                    end;
                    %
                    file_names = cell(1,num_files);
                    for i=1:num_files
                        file_names{i} = files(i).name;
                    end
                    file_names = sort_nat(file_names);
                    %
                    Z = [];
                    %
                    channels_names = cell(1,num_files);
                    %
                    hw = waitbar(0, 'Loading files to Omero, please wait');
                    for i = 1 : num_files                
                            U = imread([folder filesep file_names{i}],extension);                            
                            % rearrange planes
                            [w,h,Nch] = size(U);
                            if isempty(Z)
                                Z = zeros(num_files,h,w);           
                            end;
                            if 1 ~= Nch
                                errordlg('Single-plane images are expected - can not continue');
                                return;                                
                            end;
                            %
                            Z(i,:,:) = squeeze(U(:,:,1))';                            
                            %
                            str = split('_',file_names{i});                            
                            str1 = char(str(length(str)));
                            str2 = split('.',str1);
                            channels_names{i} = num2str(str2num(char(str2(1))));
                            %
                            waitbar(i/num_files, hw);
                            drawnow;                            
                    end
                    delete(hw);
                    drawnow;                                        
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    new_image_name = char(strings(length(strings)));
                    new_imageId = mat2omeroImage_Channels(session, Z, pixeltype, new_image_name, image_description, channels_names);
                        link = omero.model.DatasetImageLinkI;
                        link.setChild(omero.model.ImageI(new_imageId, false));
                        link.setParent(omero.model.DatasetI(Dataset.getId().getValue(), false));
                        session.getUpdateService().saveAndReturnObject(link);                                                     
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    gateway = session.createGateway();
                    image = gateway.getImage(new_imageId); 
                    add_Annotation_XML(session, image, ... 
                        'IC_PHOT_MULTICHANNEL_IMAGE_METADATA.xml', ... 
                        'IC_PHOT_MULTICHANNEL_IMAGE_METADATA_image_annotation', ... 
                        '_',...
                        'number_of_channels', cellstr(num2str(1)), 'delays', channels_names);                                                                                
                    gateway.close();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
