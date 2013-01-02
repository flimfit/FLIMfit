
function objId = upload_PlateReader_dir(session, parent, folder, fov_name_parse_function, modulo)

    objId = [];    
    if isempty(parent) || isempty(folder), return, end;    

    PlateSetups = feval(fov_name_parse_function,folder);
       
    str = split(filesep,folder);
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
            strings  = split(filesep,[folder filesep PlateSetups.names{imgind}]); % stupid...
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
                    
                    % OME ANNOTATION                    
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.BigEndian = 'true';
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.DimensionOrder = 'XYCTZ'; % does not matter
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.ID = '?????';
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.PixelType = pixeltype;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeX = h; % :)
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeY = w;
                    
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = 1;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = 1;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = 1;
                    %
                    switch modulo
                        case 'ModuloAlongC'
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = num_files;
                        case 'ModuloAlongZ'
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = num_files;
                        case 'ModuloAlongT'
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = num_files;
                    end    
                    %
                    flimXMLmetadata.Image.ContentsType = 'sample';
                    flimXMLmetadata.Image.FLIMType = 'Gated';
                    %
                    flimXMLmetadata.StructuredAnnotations.XMLAnnotation.ATTRIBUTE.ID = 'Annotation:3'; 
                    flimXMLmetadata.StructuredAnnotations.XMLAnnotation.ATTRIBUTE.Namespace = 'openmicroscopy.org/omero/dimension/modulo'; 
                    flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ATTRIBUTE.namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';     
                    switch modulo
                        case 'ModuloAlongC'
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Type = 'lifetime'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit = 'ps'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongC.Label = channels_names; 
                        case 'ModuloAlongZ'
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE.Type = 'lifetime'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE.Unit = 'ps'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongZ.Label = channels_names; 
                        case 'ModuloAlongT'
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE.Type = 'lifetime'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE.Unit = 'ps'; 
                            flimXMLmetadata.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongT.Label = channels_names; 
                    end           
                    %
                    xmlFileName = [tempdir 'metadata.xml'];
                    xml_write(xmlFileName,flimXMLmetadata);
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