function obj = marshal_object(obj,file)

    % Reads a FLIMfit_settings file into an xml node 
    % then calls marshal_object to re-initialise the 
    % current object accordingly.


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

    % Author : Sean Warren
    
   try 
   
       if obj.datasetId > 0
            parentId = java.lang.Long(obj.datasetId);
            specifier = 'omero.model.Dataset';    
       elseif obj.plateId > 0
           parentId = java.lang.Long(obj.plateId);
           specifier = 'omero.model.Plate';    
       else
           return;
       end
       
      
       session = obj.omero_data_manager.session;
       
       annotators = java.util.ArrayList;
       metadataService = session.getMetadataService();
       map = metadataService.loadAnnotations(specifier, java.util.Arrays.asList(parentId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
       annotations = map.get(parentId);
        %
        if 0 == annotations.size()
            ret = -1;
            return;
        end
        
        
        ann = [];
        
        for j = 0:annotations.size()-1
            anno_name = char(java.lang.String(annotations.get(j).getFile().getName().getValue()));
            if strcmp(anno_name, file) 
                ann = annotations.get(j);
                 originalFile = ann.getFile();        
                 rawFileStore = session.createRawFileStore();
                 rawFileStore.setFileId(originalFile.getId().getValue());
                 
                 byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
                 
                 str = char(byteArr);
                 
                 doc_node = xmlreadstring(str);
                 
                 obj = marshal_object(doc_node,'OMERO_data_series',obj);
              
                 rawFileStore.close();
                
                break;
            end
                
        end
       
       
       
       
        
    catch
       warning('FLIMfit:LoadDataSettingsFailed','Failed to load data settings file'); 
    end
         
end