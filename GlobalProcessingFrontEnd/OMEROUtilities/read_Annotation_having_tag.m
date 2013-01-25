function str = read_Annotation_having_tag(session, object, tag)
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
        map = metadataService.loadAnnotations(specifier, java.util.Arrays.asList(objId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
        annotations = map.get(objId);
        %
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
        
        % look for xml annotation
        map = metadataService.loadAnnotations(specifier, java.util.Arrays.asList(objId), java.util.Arrays.asList('ome.model.annotations.XmlAnnotation'), annotators, omero.sys.ParametersI());
        annotations = map.get(objId);
        %
            for j = 0:annotations.size()-1
                s = annotations.get(j).getTextValue().getValue();
                str = char(s)
                if strfind(str,tag)
                    return;
                end;                    
            end
        %                               
end

