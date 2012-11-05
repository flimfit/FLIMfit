function new_imageId = upload_PlateReader_dir_as_Channels_FLIM_Data(session,folder,object,PlateSetups)  
        
        for imgind = 1 : numel(PlateSetups.names)
        
        row = PlateSetups.rows(imgind);
        col = PlateSetups.cols(imgind);
        if col > PlateSetups.colMaxNum-1 || row > PlateSetups.rowMaxNum-1, errordlg('wrong col or row number'), return, end;
        
            %
            new_imageId = [];
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
                    %
                    new_image_name = char(strings(length(strings)));
                    new_imageId = mat2omeroImage_Channels(session, Z, pixeltype, new_image_name, ' ', channels_names);
                                        
                    objId = object.getId().getValue();
                    whos_object = whos_Object(session, objId);
                    
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

                    gateway = session.createGateway();                    
                    image = gateway.getImage(new_imageId); 
                    gateway.close();
                                        
                    % OME ANNOTATION                    
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.BigEndian = 'true';
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.DimensionOrder = 'XYCTZ'; % does not matter
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.ID = '?????';
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.PixelType = pixeltype;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeX = h; % :)
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeY = w;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = 1;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = num_files;
                    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = 1;
                    %
                    flimXMLmetadata.Image.ContentsType = 'sample';
                    flimXMLmetadata.Image.FLIMType = 'Gated';
                    %
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.ATTRIBUTE.ID = 'Annotation:3'; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.ATTRIBUTE.Namespace = 'openmicroscopy.org/omero/dimension/modulo'; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ATTRIBUTE.namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09'; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Type = 'lifetime'; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.NumberOfFLIMChannels = 1; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit = 'ps'; 
                    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.Label = channels_names; 
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

