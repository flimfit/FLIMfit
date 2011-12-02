function data_mapping = setup_data_mapping(obj,handles)

    mc = metaclass(obj);
    obj_prop = mc.Properties;
    handle_fields = fieldnames(handles);
        
    data_mapping = cell(0);
    
    for i=1:length(obj_prop)
        p = obj_prop{i}.Name;
        n = length(p);
        for j=1:length(handle_fields)
            h_field = handle_fields(j);
            if strncmp(p,h_field,n)
                data_mapping(end+1) = struct('property',p,'handle',handles.(handle_fields(j)),'type',h_field(n+1:end)); %#ok
            end
        end
    end

end