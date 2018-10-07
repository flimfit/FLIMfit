function [s,obj_name] = marshal_struct(file,search_name)

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

    doc_node = xmlread(file);

    obj_node = doc_node.getFirstChild();
    obj_name = char(obj_node.getNodeName);

    s = [];
    
    if strcmp(obj_name,'FLIMfit')
        nodes = obj_node.getChildNodes;
        for k=1:nodes.getLength
            next_node = nodes.item(k-1);
            obj_name = char(next_node.getNodeName);
            if strcmp(obj_name,search_name)
                s_next = read_node(next_node);
                if isempty(s)
                    s = s_next;
                else
                    s(end+1) = s_next;
                end
            end
        end
    elseif strcmp(obj_name,search_name)
        s = read_node(obj_node);
    end
            
    function s = read_node(obj_node)
    
        s = struct();
        
        child_nodes = obj_node.getChildNodes;
        n_nodes = child_nodes.getLength;

         for i=1:n_nodes
             child = child_nodes.item(i-1);
             child_name = char(child.getNodeName);
             
                               
             encoded = false; celldata = false;
             if child.hasAttributes
                 attr = child.getAttributes;
                 for j=1:attr.getLength()
                     encoded = encoded | strcmp(attr.item(j-1),'encoded="true"');
                     celldata = celldata | strcmp(attr.item(j-1),'cell="true"');
                 end
             end
             
             if child.hasChildNodes
                 val = child.getFirstChild;
                 child_value = char(val.getData);
                 
                 if encoded
                     child_value = base64decode(child_value);
                     child_value = deserialize(child_value);
                 elseif celldata
                     char_nodes = child.getChildNodes;
                     n_char = char_nodes.getLength;
                     child_value = {};
                     for j=1:n_char
                         if char_nodes.item(j-1).hasChildNodes()
                             child_value{end+1} = char(char_nodes.item(j-1).getFirstChild().getData());
                         end
                     end
                 else
                     child_value
                     child_value = eval(child_value);
                 end
                 
                 s.(child_name) = child_value;
             end
         end
         
    end
         
end