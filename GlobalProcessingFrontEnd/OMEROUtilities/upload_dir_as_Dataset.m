        function new_datasetId = upload_dir_as_Dataset(session,Project,folder,extension,modulo,bh_native_spec)
            %
            new_datasetId = [];
            %            
            strings  = split(filesep,folder);
            %
                    files = dir([folder filesep '*.' extension]);
                    num_files = length(files);
                    if 0==num_files
                        errordlg('No suitable files in the directory');
                        return;
                    end;
                    %
                    new_dataset_name = char(strings(length(strings)));
                    description = [ 'new dataset created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')]; %?? duplicate
                    new_dataset = create_new_Dataset(session,Project,new_dataset_name,description);                    
                    %
                    file_names = cell(1,num_files);
                    for i=1:num_files
                        file_names{i} = files(i).name;
                    end
                    file_names = sort_nat(file_names);
                    % 
                    hw = waitbar(0, 'Loading files to Omero, please wait');
                    for i = 1 : num_files   
                        full_file_name = [folder filesep file_names{i}];
                        if ~strcmp('sdt',extension)                            
                            if strcmp('tif',extension) && is_OME_tif(full_file_name) % that ignores "modulo" specifier!..
                                upload_Image_OME_tif(session, new_dataset,full_file_name,' ');  
                            else % try to load according to "modulo"
                                U = imread(full_file_name,extension);
                                % rearrange planes
                                [w,h,Nch] = size(U);
                                Z = zeros(Nch,h,w);
                                for c = 1:Nch,
                                    Z(c,:,:) = squeeze(U(:,:,c))';
                                end;
                                img_description = ' ';               
                                pixeltype = get_num_type(U);
                                imageId = mat2omeroImage(session, Z, pixeltype, file_names{i},  img_description, [], modulo);
                                link = omero.model.DatasetImageLinkI;
                                link.setChild(omero.model.ImageI(imageId, false));
                                link.setParent(omero.model.DatasetI(new_dataset.getId().getValue(), false));
                                session.getUpdateService().saveAndReturnObject(link); 
                            end % if strcmp('tif',extension) && is_OME_tif(full_file_name)                           
                        else % strcmp('sdt',extension)
                            upload_Image_BH(session, new_dataset,full_file_name,'sample',modulo,bh_native_spec);    
                        end
                        %
                        waitbar(i/num_files, hw);
                        drawnow;
                    end
                    delete(hw);
                    drawnow;
            %
            new_datasetId = new_dataset.getId().getValue();
        end
