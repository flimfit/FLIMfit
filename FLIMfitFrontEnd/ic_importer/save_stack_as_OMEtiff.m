 function save_stack_as_OMEtiff(folder, file_names, extension, dimension, ometiffilename)
            %
            num_files = numel(file_names);
            %
            SizeC = 1;
            SizeZ = 1;
            SizeT = 1;            
            SizeX = [];
            SizeY = [];            
            %
            if strcmp(dimension,'none'), dimension = 'C'; end; % default
            %
            switch dimension
                case 'C'
                    SizeC = num_files;
                case 'Z'
                    SizeZ = num_files;
                case 'T'
                    SizeT = num_files;
                otherwise
                    errordlg('wrong dimension specification'), return;
            end
            %                        
            all_image_data = []; % needed to calculate min, max
            %      
            hw = waitbar(0, 'Loading images...');
            for i = 1 : num_files    
            %    
                U = imread([folder filesep file_names{i}],extension);
                        %                          
                        if isempty(SizeX) % then set it up
                            [w,h] = size(U);
                            SizeX = w;
                            SizeY = h;
                            %
                            D = zeros(SizeX,SizeY,SizeZ,SizeC,SizeT);
                            
                            all_image_data = D;                            
                                switch class(U)
                                    case {'int8', 'uint8'}
                                        all_image_data = uint8(D);
                                    case {'uint16','int16'}
                                        all_image_data = uint16(D);
                                    case {'uint32','int32'}
                                        all_image_data = uint32(D);
                                    case {'single'}
                                        all_image_data = float(D);
                                    case 'double'
                                        all_image_data = D;
                                end                                
                        end % if isempty(SizeX) % then set it up
                        %
                        z = 1;
                        c = 1;
                        t = 1;
                        switch dimension
                            case 'C'
                                c = i;
                            case 'Z'
                                z = i;
                            case 'T'
                                t = i;
                        end                        
                        %
                        all_image_data(:,:,z,c,t) = U;
                        %
                        %imagesc(squeeze(all_image_data(:,:,z,c,t)));
                        %                        
                        waitbar(i/num_files,hw); drawnow;
                        %
            end  % for i = 1 : num_files                    
            delete(hw); drawnow;    
            
                        % add OME-XML to image Description - starts                            
                        metadata = loci.formats.MetadataTools.createOMEXMLMetadata();
                        metadata.createRoot();
                        metadata.setImageID('Image:0', 0);
                        metadata.setPixelsID('Pixels:0', 0);
                        metadata.setPixelsBinDataBigEndian(java.lang.Boolean.TRUE, 0, 0);
                        %    
                        % Set dimension order
                        dimensionOrderEnumHandler = ome.xml.model.enums.handlers.DimensionOrderEnumHandler();
                        dimensionOrder = dimensionOrderEnumHandler.getEnumeration('XYZCT');
                        metadata.setPixelsDimensionOrder(dimensionOrder, 0);
                        %
                        % Set pixels type
                        pixelTypeEnumHandler = ome.xml.model.enums.handlers.PixelTypeEnumHandler();
                        if isa(all_image_data,'single')
                            pixelsType = pixelTypeEnumHandler.getEnumeration('float');
                        else
                            pixelsType = pixelTypeEnumHandler.getEnumeration(class(all_image_data));
                        end
                        metadata.setPixelsType(pixelsType, 0);
                        %
                        toPosI = @(x) ome.xml.model.primitives.PositiveInteger(java.lang.Integer(x));
                        toNNI = @(x) ome.xml.model.primitives.NonNegativeInteger(java.lang.Integer(x));
                        %
                        % Read pixels size from image and set it to the metadata
                        metadata.setPixelsSizeX(toPosI(SizeX), 0);
                        metadata.setPixelsSizeY(toPosI(SizeY), 0);
                        metadata.setPixelsSizeZ(toPosI(SizeZ), 0);
                        metadata.setPixelsSizeC(toPosI(SizeC), 0);
                        metadata.setPixelsSizeT(toPosI(SizeT), 0);
                        %
                        for i = 1:num_files
                                z = 1;
                                c = 1;
                                t = 1;
                                %
                                switch dimension
                                    case 'C'
                                        c = i;
                                    case 'Z'
                                        z = i;
                                    case 'T'
                                        t = i;
                                end
                                %
                                metadata.setUUIDFileName(sprintf(char(file_names{i})),0,i-1);   
                                metadata.setUUIDValue(sprintf(dicomuid),0,i-1);                                   
                                metadata.setTiffDataPlaneCount(toPosI(z),0,i-1);                                
                                % 0-based ?
                                metadata.setTiffDataIFD(toNNI(z-1),0,i-1);
                                metadata.setTiffDataFirstZ(toNNI(z-1),0,i-1);
                                metadata.setTiffDataFirstC(toNNI(c-1),0,i-1);
                                metadata.setTiffDataFirstT(toNNI(t-1),0,i-1);                                                                
                        end                                                                                      
                        %
                        % Set channels ID and samples per pixel
                        for i = 1: SizeC
                            metadata.setChannelID(['Channel:0:' num2str(i-1)], 0, i-1);
                            metadata.setChannelSamplesPerPixel(toPosI(1), 0, i-1);
                        end                       
                        %
                        % 5.0
                        OMEXMLservice = loci.formats.services.OMEXMLServiceImpl();
                        img_description = char(OMEXMLservice.getOMEXML(metadata)); 
                        %                                                
                        % 4.0
                        %img_description = char(loci.formats.MetadataTools.getOMEXML(metadata));
                        %
                        % add OM-XML to image Description - end
            %
            bfsave_with_description_and_UUIDFileNames(all_image_data, ometiffilename, 'XYZCT', img_description, dimension, file_names);
end