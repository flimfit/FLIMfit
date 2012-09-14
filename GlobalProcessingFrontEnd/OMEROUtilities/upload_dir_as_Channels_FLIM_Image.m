        function new_imageId = upload_dir_as_Channels_FLIM_Image(session,Dataset,folder,extension,image_description)
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
                    % pixeltype...
                    U = imread([folder filesep file_names{1}],extension);                    
                    pixeltype = get_num_type(U);
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
                    %
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

                    gateway.close();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
