function store_fit_result(obj, session)

    
    if obj.has_fit
        
         res = obj.fit_result;
         
         ID = obj.data_series_list.data_series.OMERO_id;
        
         % to create a new file on the OMERO server
         imageId = java.lang.Long(ID);
   
         proxy = session.getContainerService();

         % check original image ID is valid
         ids = java.util.ArrayList();
         ids.add(imageId); %add the id of the image.
         list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());

         if (list.size == 0)
            exception = MException('OMERO:ImageID', 'Image Id not valid');
            throw(exception);
            return;
         end
         
         image = list.get(0);
         
         name = char(image.getName.getValue()); % char converts to matlab
         
         % get the dataset that contains the raw data image
         ids = java.util.ArrayList();
         ids.add(imageId); %add the id of the image.

         param = omero.sys.ParametersI;
         param.addIds(ids);
         service = session.getQueryService();
         list = service.findAllByQuery('select l from DatasetImageLink as l left outer join fetch l.parent where l.child.id =:ids ', param);

         dataset = list.get(0).getParent();
         
         datasetId = dataset.getId().getValue();
         
         list = service.findAllByQuery(['select l from ProjectDatasetLink as l where l.child.id = ',num2str(datasetId)], []);
         project = list.get(0).getParent();
        
         
        current_dataset_name = char(dataset.getName().getValue());
       
         new_dataset_name = [current_dataset_name ' analysis ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
         description  = ['analysis of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
         newdataset = create_new_Dataset(session,project,new_dataset_name,description);                                                                                                   
                 
         if isempty(newdataset)
            errordlg('Can not create new dataset');
            return;
         end
         
         
    
         % get first parameter image just to get the size
         params = res.fit_param_list();
         n_params = length(params);
         param_array(:,:) = single(obj.get_image_result_idx(1, params{1}));
         sizeY = size(param_array,1);
         sizeX = size(param_array,2);
                 %
         % assume only 1 fitted  data_set for now 
         data_set = 1;                 
                 
        data = zeros(n_params,sizeX,sizeY);
        for p = 1:n_params,
            data(p,:,:) = obj.get_image_result_idx(data_set, p)';
        end
        
        % WARNING!!
        % bodge to limit the largest number Rendering in mat2omeroImage_Channels
        % Seems to have a problem with big numbers
        data(data > 10000) = 10000; % 
                                 
        new_image_description = char(['Source Image ID:' num2str(image.getId().getValue())]);
        new_image_name = char(['Results from FLIM fitting of ' char(java.lang.String(image.getName().getValue()))]);
        imageId = mat2omeroImage_Channels(session, data, 'float', new_image_name, new_image_description, res.fit_param_list());
        link = omero.model.DatasetImageLinkI;
        link.setChild(omero.model.ImageI(imageId, false));
        link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false));
        session.getUpdateService().saveAndReturnObject(link);
        
         

       

                
    end
    
end