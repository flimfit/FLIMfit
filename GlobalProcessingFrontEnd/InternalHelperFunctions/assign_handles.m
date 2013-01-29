function assign_handles(obj,handles,callback)

    % Look through the struct handles for entries that 
    % have the same name as properties of object obj and
    % assign obj.p = handles.p.
    
    % Can help cut back on crud, but be careful not to copy unintended
    % properties!
    
    if nargin < 3
        callback = [];
    end

    mc = metaclass(obj);
    obj_prop = mc.Properties;
    handle_fields = fieldnames(handles);
    
    for i=1:length(obj_prop)
        p = obj_prop{i}.Name;
        for j=1:length(handle_fields)
            if strcmp(p,handle_fields{j})
                eval(['obj.' p ' = handles.' p ';']);
                if ~isempty(callback)
                    try
                        set(handles.(handle_fields{j}),'Callback',callback);
                    catch %#ok
                    end
                end
            end
        end
    end

end