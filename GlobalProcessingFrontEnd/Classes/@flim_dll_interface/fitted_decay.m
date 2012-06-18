function decay = fitted_decay(obj,t,im_mask,selected)

    d = obj.data_series;
    p = obj.fit_params;
        
    decay = [];
        
    if (p.split_fit || p.global_variable > 0) && ~obj.bin
        return
    end
    
    if ~d.use(selected)
        return
    end
    
    im = find(obj.datasets==selected)-1;
    
    if obj.bin
        mask = 1;
        im = 0;
    else
        mask = im_mask;
    end
    
    mask = mask(:);
    loc = 0:(length(mask)-1);
    loc = loc(mask);
    
    
    n_fit = sum(mask(:));
    n_t = length(t);
    n_chan = d.n_chan;
    
    p_fit = libpointer('doublePtr',zeros([n_t n_chan n_fit]));
    
    %try
        
        calllib(obj.lib_name,'FLIMGlobalGetFit', obj.dll_id, im, n_t, t, n_fit, loc, p_fit);
        
        decay = p_fit.Value;
        decay = reshape(decay,[n_t n_chan n_fit]);
        decay = nanmean(decay,3);
       
        
        %decay = zeros(n_t,1);
        
    %catch error
        
    %    decay = zeros(n_t,1);
    %     disp('Warning: could not get fit');
    %end
            
    clear p_fit;
    

end