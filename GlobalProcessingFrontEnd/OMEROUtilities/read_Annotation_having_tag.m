function str = read_Annotation_having_tag(session, object, ome_model_annotation_type, tag)
        %
        str = [];
        %
        switch whos_Object(session,object.getId().getValue())
            case 'Project'
                specifier = 'omero.model.Project';
            case 'Dataset'
                specifier = 'omero.model.Dataset';
            case 'Image'
                specifier = 'omero.model.Image';
            case 'Plate'
                specifier = 'omero.model.Plate';
            case 'Screen'
                specifier = 'omero.model.Screen';                
        end;
        %
        objId = java.lang.Long(object.getId().getValue());
        %
        annotators = java.util.ArrayList;    
        metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations(specifier, java.util.Arrays.asList(objId), java.util.Arrays.asList(ome_model_annotation_type), annotators, omero.sys.ParametersI());
        annotations = map.get(objId);
        %        
        switch ome_model_annotation_type
            case 'ome.model.annotations.FileAnnotation'        
                rawFileStore = session.createRawFileStore();
                %
                    for j = 0:annotations.size()-1
                        originalFile = annotations.get(j).getFile();        
                        rawFileStore.setFileId(originalFile.getId().getValue());            
                        byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
                        curr_str = char(byteArr');
                        %
                        if ~isempty(strfind(curr_str,tag))
                            str = curr_str;
                            rawFileStore.close();
                            return;                
                        end                        
                    end
                %
                rawFileStore.close();
            case 'ome.model.annotations.XmlAnnotation'                        
                for j = 0:annotations.size()-1
                    s = annotations.get(j).getTextValue().getValue();
                    str = char(s);
                    if strfind(str,tag)
                        return;
                    end;                    
                end                              
        end % switch
end

