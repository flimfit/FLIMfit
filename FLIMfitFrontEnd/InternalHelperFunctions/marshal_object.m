function obj = marshal_object(doc_node,type,obj)

    % Re-initialises  an object using the values in the xml node (previously read from a FLIMfit_settings file )
    % if the object is not  icluded in the arg list  a new object is created of the type specified by 'type'
    % 

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

    obj_node = doc_node.getFirstChild();
    obj_name = char(obj_node.getNodeName);
    
    if strcmp(obj_name,'FLIMfit')
        obj_node = obj_node.getChildNodes().item(1);
        obj_name = char(obj_node.getNodeName);
    end

    mc = meta.class.fromName(obj_name);
    
    if isempty(mc)
        MException('FLIM:UnrecognisedObject','Object specified by XML was not recognised')
    end

    if nargin == 2 && ~strcmp(obj_name,type)
        MException('FLIM:UnexpectedObject','Object specified by XML was not of the type expected')
    end

    if nargin < 3
        eval(['obj = ' obj_name '();']);
    end

    child_nodes = obj_node.getChildNodes;
    n_nodes = child_nodes.getLength;

     for i = 1:n_nodes
         child = child_nodes.item(i-1);
         child_name = char(child.getNodeName);


         encoded = false;
         if child.hasAttributes
             attr = child.getAttributes;
             for j=1:attr.getLength()
                 if strcmp(attr.item(j-1),'encoded="true"')
                     encoded = true;
                 end
             end
         end

         if child.hasChildNodes && ~isempty(findprop(obj,child_name))
             val = child.getFirstChild;
             child_value = char(val.getData);

             if encoded
                 child_value = base64decode(child_value);
                 child_value = deserialize(child_value);

             else
                 child_value = eval(child_value);
             end
             try 
                obj.(child_name) = child_value;
             catch
                warning('FLIMfit:LoadDataSettingsFailed',['Failed to load setting: ' child_name]); 
             end
         end
     end

         
end