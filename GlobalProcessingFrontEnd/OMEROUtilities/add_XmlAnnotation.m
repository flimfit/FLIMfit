function ret = add_XmlAnnotation(session,object,Xml,namespace)
        %
        ret = false;
        %
        if isempty(Xml) || isempty(session) || isempty(object)
            return;
        end;
                                    
        iUpdate = session.getUpdateService(); % service used to write object
        
        strXml = xmlwrite(Xml);
             
        term = omero.model.XmlAnnotationI;
        term.setTextValue(omero.rtypes.rstring(strXml));
        term.setNs(omero.rtypes.rstring(namespace));
        link = omero.model.ImageAnnotationLinkI;  
        link.setChild(term);
        link.setParent(object);
        
                                           
        whos_object = whos_Object(session,object.getId().getValue());
        switch whos_object
            case 'Project'
                link = omero.model.ProjectAnnotationLinkI;
            case 'Dataset'
                link = omero.model.DatasetAnnotationLinkI;
            case 'Image'
                link = omero.model.ImageAnnotationLinkI;                
            case 'Screen'
                link = omero.model.ScreenAnnotationLinkI;                
            case 'Plate'
                link = omero.model.PlateAnnotationLinkI;                                
        end;
        %
        if strcmp('unknown',whos_Object(session,object.getId().getValue()))
            link = omero.model.ImageAnnotationLinkI;
        end;
        %
        link.setChild(term);
        link.setParent(object);
        % save the link back to the server.
        iUpdate.saveAndReturnObject(link);
        

        ret = true;    
end
