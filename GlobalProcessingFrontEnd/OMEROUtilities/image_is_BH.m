function ret = image_is_BH(session,image)

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

