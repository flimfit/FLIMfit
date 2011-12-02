function load_fit_result(obj,file)

    obj.has_fit = true;
    
    obj.fit_result = flim_fit_result();
    obj.fit_result.load(file);

end