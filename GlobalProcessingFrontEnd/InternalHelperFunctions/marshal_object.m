function obj = marshal_object(file,type,obj)

   try 
        doc_node = xmlread(file);

        obj_node = doc_node.getFirstChild();
        obj_name = char(obj_node.getNodeName);

        mc = meta.class.fromName(obj_name);
        mp = mc.Properties;

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
                 for j=1:attr.getLength();
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
                 
                 obj.(child_name) = child_value;
             end
         end
    catch
       warning('GlobalProcessing:LoadDataSettingsFailed','Failed to load data settings file'); 
    end
         
end