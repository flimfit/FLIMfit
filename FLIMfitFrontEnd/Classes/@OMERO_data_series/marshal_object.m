function obj = marshal_object(obj,file, originalFile)

    % Reads a FLIMfit .xml file into an xml node 
    % then calls marshal_object to re-initialise the 
    % current object accordingly.
    % Uses the supplied oroginalFile if available otherwise searches the 
    % currene dataset/plate for Attachments with a matching name.


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
 
    
  try 
  
  session = obj.omero_logon_manager.session;
  
  if nargin < 3   % no originalFile supplied so search
      
      if obj.datasetId > 0
          parentId = obj.datasetId;
          annotations = getDatasetFileAnnotations(session, parentId);
      elseif obj.plateId > 0
          parentId = obj.plateId;
          annotations = getPlateFileAnnotations(session, parentId);
      else
          return;
      end
      
      
      na = length(annotations);
      if na  == 0
          ret = -1;
          return;
      end
      
      name_found = false;
      
      for j = 1:na
          originalFile = annotations(j).getFile();
          anno_name = char(originalFile.getName().getValue());
          if strcmp(anno_name, file)
              name_found = true;
              break;
          end
          
      end
      
      % no matching Attachment found
      if ~name_found
          ret = -1;
          return;
      end
      
  end
  
  
  context = java.util.HashMap;
  context.put('omero.group', '-1');
  rawFileStore = session.createRawFileStore();
  rawFileStore.setFileId(originalFile.getId().getValue());
  
  byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
  
  str = char(byteArr);
  
  doc_node = xmlreadstring(str);
  
  obj = marshal_object(doc_node,'OMERO_data_series',obj);
  
  rawFileStore.close();
  
  
  
  catch
    warning('FLIMfit:LoadDataSettingsFailed','Failed to load data settings file');
  end
  
end