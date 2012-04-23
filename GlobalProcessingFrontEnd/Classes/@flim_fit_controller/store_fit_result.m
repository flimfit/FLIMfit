function store_fit_result(obj, session)

    
    if obj.has_fit
        
         res = obj.fit_result;
         
         ID = obj.data_series_list.data_series.OMERO_id;
        
        
         % to create a new file on the OMERO server
         imageId = java.lang.Long(ID);
   
         proxy = session.getContainerService();

         % check original image ID is valid
         list = proxy.getImages(omero.model.Image.class, java.util.Arrays.asList(imageId), omero.sys.ParametersI());
         if (list.size == 0)
            exception = MException('OMERO:ImageID', 'Image Id not valid');
            throw(exception);
            return;
         end
         
         image = list.get(0);
         
         name = char(image.getName.getValue()); % char converts to matlab
    
         
         store = session.createRawPixelsStore(); 
         proxy = session.getPixelsService();

         % Create the new image
         description = char(['Source Image ID:' num2str(ID) ]);
         name = char(['Results from FLIM fitting of ' name ]);

         typeNew = omero.model.PixelsTypeI;
         typeNew.setValue(omero.rtypes.rstring(char('float')));
         
         % get first parameter image just to get the size
         params = res.fit_param_list();
         n_params = length(params);
         par = params{1};
         param_array(:,:) = single(res.get_image(1, par));
         sizeY = size(param_array,1);
         sizeX = size(param_array,2);
         sizeZ = 1;
         sizeT = 1;
         

         idNew = proxy.createImage(sizeX, sizeY, sizeZ, sizeT, toJavaList([uint32(0:(n_params - 1))]) , typeNew, name, description);


         proxy = session.getContainerService();

         % load the new image
         list = proxy.getImages(omero.model.Image.class, java.util.Arrays.asList(java.lang.Long(idNew.getValue())), omero.sys.ParametersI());
         if (list.size == 0)
            exception = MException('OMERO:ImageID', 'Image Id not valid');
            throw(exception);
         return;
         end

         imageNew = list.get(0);


         % get the dataset that contains the raw data image
         ids = java.util.ArrayList();
         ids.add(imageId); %add the id of the image.

         param = omero.sys.ParametersI;
         param.addIds(ids);
         service = session.getQueryService();
         list = service.findAllByQuery(['select l from DatasetImageLink as l where l.child.id = ', num2str(ID)], []);
         dataset = list.get(0).getParent();


         %link the new image to the same  dataset.
         link = omero.model.DatasetImageLinkI;

         link.setChild(omero.model.ImageI(imageNew.getId().getValue(), false));
         link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));

         session.getUpdateService().saveAndReturnObject(link);


   
         %Copy the data.
         pixelsNewList = imageNew.copyPixels();

         pixelsNew = pixelsNewList.get(0);

         service = session.getPixelsService();

         % retrieve information about the pixels.
         pixelsDesc = service.retrievePixDescription(pixelsNew.getId().getValue());
         channels = pixelsDesc.copyChannels();


         pixelsNewId = pixelsNew.getId().getValue();
         store = session.createRawPixelsStore();
         store.setPixelsId(pixelsNewId, false);

         
         % write the first  parameter (already loaded to get size) to the zeroth channel in the OMERO file
         c = channels.get(0);
         c.getLogicalChannel().setName(omero.rtypes.rstring(par));
         session.getUpdateService().saveAndReturnObject(c.getLogicalChannel());  % better to update all channels at once somehow?
         
         param_vec = reshape(param_array, sizeY * sizeX, 1);
         param_vec = swapbytes(param_vec);
         vec_as_int8 = typecast(param_vec,'int8');
         store.setPlane(vec_as_int8, 0, 0, 0); % copy the raw data
         
         % assume only 1 fitted  dataset for now 
         dataset = 1;
         % for dataset = 1:n_results
            for p = 2:n_params
                par = params{p};
                param_array(:,:) = single(res.get_image(dataset, par));
                
                % write this parameter to a channel in the OMERO file
                c = channels.get(p - 1);
                c.getLogicalChannel().setName(omero.rtypes.rstring(par));
                session.getUpdateService().saveAndReturnObject(c.getLogicalChannel());  % better to update all channels at once somehow?
                
                param_vec = reshape(param_array, sizeY * sizeX, 1);
                param_vec = swapbytes(param_vec);
                vec_as_int8 = typecast(param_vec,'int8');
                store.setPlane(vec_as_int8, 0, p - 1, 0); % copy the raw data
                
            end
         % end
        
        

         %save the data
         store.save();


         store.close()

                
    end
    
end