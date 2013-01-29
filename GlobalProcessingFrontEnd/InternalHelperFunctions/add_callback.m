function add_callback(object,callback)

    if isempty(object)
        return;
    end

    old_callback = get(object,'Callback');
    if ~isempty(old_callback)
        new_callback = @cb;
    else
        new_callback = callback;
    end

    set(object,'Callback',new_callback);

    function cb(x,y)
        old_callback(x,y);
        callback(x,y);
    end
    
end