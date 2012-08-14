        function ret = image_is_BH(session,image)
            ret = false;            
            metadataService = session.getMetadataService();
            map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(java.lang.Long(image.getId().getValue())), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), java.util.ArrayList, omero.sys.ParametersI());                                              
            annotations = map.get(java.lang.Long(image.getId().getValue()));
            %               
            for k = 0:annotations.size()-1                                    
                 if annotations.get(k).getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)                                                                       
                     ann = annotations.get(k);                                                               
                     originalFile = ann.getFile();                                    
                     %annfname = char(java.lang.String(originalFile.getName().getValue()))                               
                     rawFileStore = session.createRawFileStore();
                     rawFileStore.setFileId(originalFile.getId().getValue());
                     %  open file and read it
                     byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
                     str = char(byteArr');
                     rawFileStore.close();
                     %
                     if strfind(str,'bhfileHeader')
                        ret = true;
                            break;                                    
                     end                                    
                 end
            end                                                                                                                        
        end        

