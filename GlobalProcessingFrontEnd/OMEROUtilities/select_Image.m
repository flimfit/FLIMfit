        function ret = select_Image(session,Parent)        
            %
            ret = [];
            %
            if isempty(Parent) 
                errordlg('Parent not defined');
                return;
            end;                   
            %
            pName = char(java.lang.String(Parent.getName().getValue()));
            
            parent_is = whos_Object(session,Parent.getId().getValue());
            
            if strcmp(parent_is,'Dataset') % load images from Dataset

                imageList = Parent.linkedImageList;
                %       
                if 0==imageList.size()
                    errordlg(['Dataset ' pName ' have no images'])
                    return;
                end;                                    
                %        
                 z = 0;       
                 str = char(256,256);
                 for k = 0:imageList.size()-1,                       
                         z = z + 1;                                                       
                         iName = char(java.lang.String(imageList.get(k).getName().getValue()));                                                                
                         idName = num2str(imageList.get(k).getId().getValue());
                         image_name = [ idName ' : ' iName ]; 
                         str(z,1:length(image_name)) = image_name;
                  end 

                str = str(1:imageList.size(),:);
                %
                [s,v] = listdlg('PromptString',['Select an Image in ' pName ' Dataset'],...
                                'SelectionMode','single',...
                                'ListString',str);
                %
                if(v)
                    ret = imageList.get(s-1);
                end            
                
            elseif strcmp(parent_is,'Plate') % load images from plate

                 z = 0;       
                 images = [];
                 str = char(256,256);
                 
                            wellList = session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(Parent.getId().getValue())],[]);
                            for j = 0:wellList.size()-1,
                                well = wellList.get(j);
                                wellsSampleList = well.copyWellSamples();
                                well.getId().getValue();
                                for i = 0:wellsSampleList.size()-1,
                                    ws = wellsSampleList.get(i);
                                    ws.getId().getValue();
                                    % pa = ws.getPlateAcquisition();
                                    z = z + 1;
                                    image = ws.getImage();
                                    iid = image.getId().getValue();
                                    idName = num2str(image.getId().getValue());
                                    iName = char(java.lang.String(image.getName().getValue()));
                                    image_name = [ idName ' : ' iName ];
                                    str(z,1:length(image_name)) = image_name;
                                    images(z) = iid;
                                end
                            end
                                        
                str = str(1:numel(images),:);
                %
                [s,v] = listdlg('PromptString',['Select Plate Image'],...
                                'SelectionMode','single',...
                                'ListString',str);
                %
                if(v)
                     ids = java.util.ArrayList();
                     ids.add(java.lang.Long(images(s))); %add the id of the image.
                      proxy = session.getContainerService();
                     list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
                     if (list.size == 0)
                        exception = MException('OMERO:ImageID', 'Image Id not valid');
                        throw(exception);
                     end
                     ret = list.get(0);
                end 
                
            end
        end                      
