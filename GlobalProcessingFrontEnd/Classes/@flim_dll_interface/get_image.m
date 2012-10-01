function [param_data mask] = get_image(obj,im,param)

    param_data = 0;
    mask = 0;
        
    
    if (obj.bin || param == 0)
        return
    end
            
    sz = obj.im_size;
    
    dataset = obj.datasets(im);
    
    p_mask = libpointer('uint8Ptr', zeros(sz));
    p_param_data = libpointer('singlePtr', zeros(sz));

    err = calllib(obj.lib_name,'GetParameterImage',obj.dll_id, dataset-1, param-1, p_mask, p_param_data);
    
    mask = p_mask.Value;
    mask = reshape(mask, sz);
    
    param_data = p_param_data.Value;
    param_data = reshape(param_data, sz);

end