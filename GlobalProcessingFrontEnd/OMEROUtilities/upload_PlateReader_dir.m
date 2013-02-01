
function objId = upload_PlateReader_dir(session, parent, folder, fov_name_parse_function, modulo)

    objId = [];    
    if isempty(parent) || isempty(folder), return, end;    

    PlateSetups = feval(fov_name_parse_function,folder);
       
    %str = split(filesep,folder);
    strings1 = strrep(folder,filesep,'/');
    str = split('/',strings1);                            
        
    newdataname = str(length(str));
    
    whos_parent = whos_Object(session,parent.getId().getValue());
    
    if strcmp('Screen',whos_parent) % append new Plate: data -> Plate -> Screen
        updateService = session.getUpdateService();        
            newdata = omero.model.PlateI();
            newdata.setName(omero.rtypes.rstring(newdataname));    
            newdata.setColumnNamingConvention(omero.rtypes.rstring(PlateSetups.columnNamingConvention));
            newdata.setRowNamingConvention(omero.rtypes.rstring(PlateSetups.rowNamingConvention));            
            newdata = updateService.saveAndReturnObject(newdata);
            link = omero.model.ScreenPlateLinkI;
            link.setChild(newdata);            
            link.setParent(omero.model.ScreenI(parent.getId().getValue(),false));            
        updateService.saveObject(link);        
    elseif strcmp('Project',whos_parent) % append new Dataset: data -> Dataset -> Project
            description = [ 'new dataset created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
            newdata = create_new_Dataset(session,parent,newdataname,description);                            
    end

    objId = newdata.getId().getValue();
    whos_object = whos_Object(session,objId);
            
            for imgind = 1 : numel(PlateSetups.names)
        
            row = PlateSetups.rows(imgind);
            col = PlateSetups.cols(imgind);
            if col > PlateSetups.colMaxNum-1 || row > PlateSetups.rowMaxNum-1, errordlg('wrong col or row number'), return, end;
            %            
            %strings  = split(filesep,[folder filesep PlateSetups.names{imgind}]); % stupid...
             strings1 = strrep([folder filesep PlateSetups.names{imgind}],filesep,'/');
             strings = split('/',strings1);                            
            %
            %%%%%%%%%%%%%%%%%%%%%%%%% that works only for tiffs....                         
                    files = dir([folder filesep PlateSetups.names{imgind} filesep '*.' PlateSetups.extension]);
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
                    % pixeltype...
                    U = imread([folder filesep PlateSetups.names{imgind} filesep file_names{1}],PlateSetups.extension);                    
                    pixeltype = get_num_type(U);
                    %                                                            
                    Z = [];
                    %
                    channels_names = cell(1,num_files);
                    %
                    hw = waitbar(0, 'Loading files to Omero, please wait');
                    for i = 1 : num_files                
                            U = imread([folder filesep PlateSetups.names{imgind} filesep file_names{i}],PlateSetups.extension);                            
                            % rearrange planes
                            [w,h,Nch] = size(U);
                            %
                            if 1 ~= Nch
                                errordlg('Single-plane images are expected - can not continue');
                                return;                                
                            end;
                            %
                            if isempty(Z)
                                Z = zeros(num_files,h,w);           
                            end;
                            %
                            Z(i,:,:) = squeeze(U(:,:,1))';                            
                            %
                            fnamestruct = feval(PlateSetups.DelayedImageFileNameParsingFunction,file_names{i});
                            channels_names{i} = fnamestruct.delaystr; % delay [ps] in string format
                            %
                            waitbar(i/num_files, hw);
                            drawnow;                            
                    end
                    delete(hw);
                    drawnow;                                        
                    %
                    new_image_name = char(strings(length(strings)));
                    new_imageId = mat2omeroImage(session, Z, pixeltype, new_image_name, ' ', channels_names, modulo);
                                                                           
                    if strcmp('Plate',whos_object)                                                     
                        updateService = session.getUpdateService();
                        well = omero.model.WellI;    
                        well.setColumn( omero.rtypes.rint(col) );
                        well.setRow( omero.rtypes.rint(row) );
                        well.setPlate( omero.model.PlateI(objId,false) );
                        well = updateService.saveAndReturnObject(well);        
                        ws = omero.model.WellSampleI();
                        ws.setImage( omero.model.ImageI(new_imageId,false) );
                        ws.setWell( well );        
                        well.addWellSample(ws);
                        ws = updateService.saveAndReturnObject(ws);                                                        
                    elseif strcmp('Dataset',whos_object)                        
                        link = omero.model.DatasetImageLinkI;
                        link.setChild(omero.model.ImageI(new_imageId, false));
                        link.setParent(omero.model.DatasetI(objId, false));
                        session.getUpdateService().saveAndReturnObject(link);                                                                             
                    end                        

%                     gateway = session.createGateway();                    
%                     image = gateway.getImage(new_imageId); 
%                     gateway.close();
                    %get image without gateway;
                    id = java.util.ArrayList();
                    id.add(java.lang.Long(new_imageId)); %id of the image
                    proxy = session.getContainerService();
                    list = proxy.getImages('Image', id, omero.sys.ParametersI());
                    image = list.get(0);
                    % 
                    ome_params.BigEndian = 'true';
                    ome_params.DimensionOrder = 'XYCTZ';
                    ome_params.pixeltype = pixeltype;
                    ome_params.SizeX = h;
                    ome_params.SizeY = w;
                    ome_params.SizeZ = 1;
                    ome_params.SizeC = 1;
                    ome_params.SizeT = 1;
                    ome_params.modulo = modulo;
                    ome_params.delays = channels_names;
                    ome_params.FLIMType = 'Gated';
                    ome_params.ContentsType = 'sample';
                    %
                    xmlFileName = write_OME_FLIM_metadata(ome_params); 
                    %
                    namespace = 'IC_PHOTONICS';
                    description = ' ';
                    %
                    sha1 = char('pending');
                    file_mime_type = char('application/octet-stream');
                    %
                    add_Annotation(session, ...
                                    image, ...
                                    sha1, ...
                                    file_mime_type, ...
                                    xmlFileName, ...
                                    description, ...
                                    namespace);    
                    %
                    delete(xmlFileName);                    
            end        
           
end