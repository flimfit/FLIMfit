function save_fit_result(obj,file)

    if obj.has_fit
        obj.fit_result.save(file);
    end
    
end