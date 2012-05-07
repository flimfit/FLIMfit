function decay = fitted_decay(obj,t,im_mask,selected)

    d = obj.data_series;
    p = obj.fit_params;

    if p.split_fit && ~obj.bin
        decay = [];
        return
    end
    
    if ~d.use(selected)
        return
    end
        
    n_group = sum(d.use);
    n_x = size(im_mask,1);
    n_y = size(im_mask,2);

    if obj.bin
        mask = 1;
    else
        mask = im_mask;
    end
    
    %mask = mask';
    mask = mask(:);
    loc = 0:(length(mask)-1);
    loc = loc(mask);
    
    
    n_fit = sum(mask(:));
    n_t = length(t);
    n_chan = d.n_chan;
    
    p_fit = libpointer('doublePtr',zeros([n_t n_chan n_fit]));
    
    %try
        
        calllib(obj.lib_name,'FLIMGlobalGetFit', obj.dll_id, selected-1, n_t, t, n_fit, loc, p_fit);
        
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