function [ret fname] = select_Annotation(session, object, prompt)
        %
        ret = [];
        %
        switch whos_Object(session,object.getId().getValue())
            case 'Project'
                specifier = 'omero.model.Project';
            case 'Dataset'
                specifier = 'omero.model.Dataset';
            case 'Image'
                specifier = 'omero.model.Image';
        end;
        %
        objId = java.lang.Long(object.getId().getValue());
        %
        annotators = java.util.ArrayList;    
        metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations(specifier, java.util.Arrays.asList(objId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
        annotations = map.get(objId);
        %
        if 0 == annotations.size()
            errordlg('select_Annotation: no annotations - ret is empty');
        end                
        %        
        str = char(256,256);
        z = 0;
        for j = 0:annotations.size()-1
            anno_j_name = char(java.lang.String(annotations.get(j).getFile().getName().getValue()));
            z = z + 1;
            str(z,1:length(anno_j_name)) = anno_j_name;
        end
        %
        str = str(1:annotations.size(),:);
        %
        [s,v] = listdlg('PromptString',prompt,...
                            'SelectionMode','single',...
                            'ListString',str);
        %
        if(v)
            ann = annotations.get(s-1);
            fname = char(java.lang.String(ann.getFile().getName().getValue()));
        else
            return;
        end;
        %
        originalFile = ann.getFile();        
        rawFileStore = session.createRawFileStore();
        rawFileStore.setFileId(originalFile.getId().getValue());
        %
        byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
        %
        %ret = char(byteArr'); ?!        
        ret = byteArr;
        %
	    rawFileStore.close();
end

