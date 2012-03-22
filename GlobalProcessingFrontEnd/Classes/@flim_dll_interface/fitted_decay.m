function decay = fitted_decay(obj,t,im_mask,selected)

    d = obj.data_series;
    p = obj.fit_params;

    if p.split_fit && ~obj.bin
        decay = [];
        return
    end
        

    
    n_group = d.n_datasets;
    n_x = size(im_mask,1);
    n_y = size(im_mask,2);
    
    if obj.bin
        group = 0;
        n_ret_group = 1;
        mask = 1;
    else
        switch (p.global_fitting)
            case 0 % global_mode.pixel
                n_ret_group = n_x*n_y;
                group = (selected-1)*n_x*n_y;
                mask = im_mask;
            case 1 %global_mode.image
                n_ret_group = 1;
                group = selected-1;
                mask = im_mask;
            case 2 %global_mode.dataset
                n_ret_group = 1;
                group = 0;
                mask = zeros([size(im_mask) n_group]);
                mask(:,:,selected) = im_mask;
        end     
        
    end
    
    n_fit = sum(mask(:));
    n_t = length(t);
    n_chan = d.n_chan;
    
    p_fit = libpointer('doublePtr',zeros([n_t n_chan n_fit]));
    
    try
        
        calllib(obj.lib_name,'FLIMGlobalGetFit', obj.dll_id, group, n_ret_group, n_fit, mask, n_t, t, p_fit);
        
        decay = p_fit.Value;
        decay = reshape(decay,[n_t n_chan n_fit]);
        decay = nanmean(decay,3);
       
        
        %decay = zeros(n_t,1);
        
    catch error
        
        decay = zeros(n_t,1);
        
    end
            
    clear p_fit;
    

end