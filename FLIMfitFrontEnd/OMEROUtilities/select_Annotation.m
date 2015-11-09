function [ret fname] = select_Annotation(session, userId, object, prompt)

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
     
        if isempty(userId)
            userId = session.getAdminService().getEventContext().userId;
        end
        %
        ret = [];
        fname = [];
        
        
        class_names = getObjectTypes();       
        for k = 1:length(class_names)
            if strfind(class(object),class_names(k).class);
                parentType = class_names(k).class;
                break;
            end;
        end
              
        
        objId = java.lang.Long(object.getId().getValue());
        
        annotators = java.util.ArrayList;    
        metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations(parentType, java.util.Arrays.asList(objId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
        annotations = map.get(objId);
        
        if 0 == annotations.size()
            ret = -1;
            return;
        end                
       
        for j = 0:annotations.size()-1
            anno_names{j+1} = char(java.lang.String(annotations.get(j).getFile().getName().getValue()));
        end
         
        [s,v] = listdlg('PromptString',prompt,...
                            'SelectionMode','single',...
                            'ListSize',[300 300],...                            
                            'ListString',anno_names);
        
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
           
        ret = byteArr;
        
	    rawFileStore.close();
end

