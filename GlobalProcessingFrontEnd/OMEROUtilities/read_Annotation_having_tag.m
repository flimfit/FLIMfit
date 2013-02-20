function str = read_Annotation_having_tag(session, object, ome_model_annotation_type, tag)

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

