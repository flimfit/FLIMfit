function ret = add_XmlAnnotation(session,object,Xml)

% add_XmlAnnotation adds an OMERO XmlAnnotation
%
% ret = add_XmlAnnotation(session,object,Xml,namespace)
% creates a new XmlAnnotation linked to the object
% and sets the namespace. Xml must be a valid DOM
% functio returns true if successful

        % Copyright (C) 2013 Imperial College London.
        % All rights reserved.
        %
        % This program is free software; you can redistribute it and/or modify
        % it under the terms of the GNU General Public License as published by
        % the Free Software Foundation; either version 2 of the License, or
        % (at your option) any later version.
        %
        % This program is distributed in the hope that it will be useful,
        % but WITHOUT ANY WARRANTY; without even the implied warranty of
        % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        % GNU General Public License for more details.
        %
        % You should have received a copy of the GNU General Public License along
        % with this program; if not, write to the Free Software Foundation, Inc.,
        % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
        %
        % This software tool was developed with support from the UK 
        % Engineering and Physical Sciences Council 
        % through  a studentship from the Institute of Chemical Biology 
        % and The Wellcome Trust through a grant entitled 
        % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
        

        ret = false;
        %
        if isempty(Xml) || isempty(session) || isempty(object)
            return;
        end;


        namespace  = 'openmicroscopy.org/omero/dimension/modulo';
                                    
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
