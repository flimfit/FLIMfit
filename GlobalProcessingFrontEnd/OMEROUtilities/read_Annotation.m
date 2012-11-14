function str = read_Annotation(session, object, filename)
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
        ann = [];
        %
        for j = 0:annotations.size()-1
            of = annotations.get(j);            
% %             if of.getFile().getName().getValue().contains(filename)
% %                 ann = annotations.get(j);
% %             end
            if strcmp(of.getFile().getName().getValue(),filename)
                ann = annotations.get(j);
            end
        end
        %
        if isempty(ann)
            return;
        end;
        %
        originalFile = ann.getFile();        
        rawFileStore = session.createRawFileStore();
        rawFileStore.setFileId(originalFile.getId().getValue());
        %
        byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
        str = char(byteArr');
	rawFileStore.close();
end

