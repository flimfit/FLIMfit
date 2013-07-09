function imageId = upload_dir_as_Omero_Image(session,dataset,folder,extension,modulo,namespace)

            if strcmp(extension,'tif') || strcmp(extension,'tiff')
                files = dir([folder filesep '*.' 'tif*']);
            else
                files = dir([folder filesep '*.' extension]);
            end
            %
            num_files = length(files);
            if 0==num_files
                errordlg('No suitable files in the directory');
                return;
            end;
                  
            file_names = cell(1,num_files);
            for i=1:num_files
                file_names{i} = files(i).name;
            end
            %
            SizeC = 1;
            SizeZ = 1;
            SizeT = 1;            
            SizeX = [];
            SizeY = [];            
            %
            switch modulo
                case 'ModuloAlongC'
                    SizeC = num_files; % 128 OK, 255 - problems...
                case 'ModuloAlongZ'
                    SizeZ = num_files;
                case 'ModuloAlongT'
                    SizeT = num_files;
                otherwise
                    errordlg('wrong modulo specification'), return;
            end
            
            queryService = session.getQueryService();
            pixelsService = session.getPixelsService();
            rawPixelsStore = session.createRawPixelsStore(); 
            containerService = session.getContainerService();

            hw = waitbar(0, 'Loading images...');
            for i = 1 : num_files    
                                                                                                      
            U = imread([folder filesep file_names{i}],extension);
                                                  
                        if isempty(SizeX)
                            [w,h] = size(U);
                            SizeX = w;
                            SizeY = h;  
                            %
                            imageName = folder;
                            img_description = ' ';               
                            pixeltype = get_num_type(U);                        
                            %
                            % Lookup the appropriate PixelsType, depending on the type of data you have:
                            p = omero.sys.ParametersI();
                            p.add('type',rstring(pixeltype));       
                            q=['from PixelsType as p where p.value= :type'];
                            pixelsType = queryService.findByQuery(q,p);

                            % Use the PixelsService to create a new image of the correct dimensions:
                            iId = pixelsService.createImage(SizeX, SizeY, SizeZ, SizeT, toJavaList([uint32(0:(SizeC - 1))]), pixelsType, imageName, img_description);
                            imageId = iId.getValue();

                            % Then you have to get the PixelsId from that image, to initialise the rawPixelsStore. I use the containerService to give me the Image with pixels loaded:
                            image = containerService.getImages('Image',  toJavaList(uint64(imageId)),[]).get(0);
                            pixels = image.getPrimaryPixels();
                            pixelsId = pixels.getId().getValue();
                            rawPixelsStore.setPixelsId(pixelsId, true);                             
                        end    
                        %   
                        plane = U;   
                        bytear = ConvertClientToServer(pixels, plane);                        
                        %                        
                        switch modulo
                            case 'ModuloAlongC'
                                rawPixelsStore.setPlane(bytear, int32(0),int32(i-1),int32(0));                
                            case 'ModuloAlongZ'
                                rawPixelsStore.setPlane(bytear, int32(i-1),int32(0),int32(0));        
                            case 'ModuloAlongT'
                                rawPixelsStore.setPlane(bytear, int32(0),int32(0),int32(i-1));        
                        end        
                        %                                                
                        waitbar(i/num_files,hw);
                        drawnow;
            end
                    
                  delete(hw);
                  drawnow;                 
                    
                  link = omero.model.DatasetImageLinkI;
                  link.setChild(omero.model.ImageI(imageId, false));
                  link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                  session.getUpdateService().saveAndReturnObject(link);                                                                             

                  % ModuloAlong annotation
                  if isempty(namespace)
                    namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';
                  end
                  %  
                  node = com.mathworks.xml.XMLUtils.createDocument('Modulo');
                  Modulo = node.getDocumentElement;
                  Modulo.setAttribute('namespace',namespace);
                  %
                  ModuloAlong = node.createElement(modulo);
                  ModuloAlong.setAttribute('TypeDescription','Single_Plane_Image_File_Names');
                  %
                  for m = 1:num_files                   
                    thisElement = node.createElement('Label');
                    thisElement.appendChild(node.createTextNode(file_names{m}));
                    ModuloAlong.appendChild(thisElement);
                  end  
                  %
                  Modulo.appendChild(ModuloAlong);
                                        
                  id = java.util.ArrayList();
                  id.add(java.lang.Long(imageId)); %id of the image
                  containerService = session.getContainerService();
                  list = containerService.getImages('Image', id, omero.sys.ParametersI());
                  image = list.get(0);
                  % 
                  add_XmlAnnotation(session,[],image,node);
                    
                  rawPixelsStore.close();                                                                                                  
end