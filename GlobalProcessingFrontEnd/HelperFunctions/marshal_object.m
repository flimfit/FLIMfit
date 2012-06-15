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
             if child.hasChildNodes && ~isempty(findprop(obj,child_name))
                child_value = char(child.getFirstChild.getData);
                obj.(child_name) = eval(child_value);
             end
         end
    catch
       warning('GlobalProcessing:LoadDataSettingsFailed','Failed to load data settings file'); 
    end
         
end