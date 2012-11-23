function bg_data = generate_tvb_I_map(obj, mask, dataset)

    decay = obj.get_roi(mask, dataset);
    decay = mean(decay,3);
    decay(decay<0) = 0;
    n = 4;
    nt = 5;
        
    Idecay = repmat(decay,[1 1 obj.height obj.width]);
    
    I = obj.cur_tr_data ./ Idecay;
    I = squeeze(mean(mean(I,1),2));
    
    f=figure('Units','Pixels');
    p = get(f,'Position');
    p(2:4) = [200,400,600];
    set(f,'Position',p);
    
    subplot(2,1,1);
    plot(obj.tr_t,decay);
    
    subplot(2,1,2);
    imagesc(I);
    daspect([1,1,1]);
    colorbar
    
    bg_data = struct('t_bg',obj.tr_t,'tvb_profile',decay,'tvb_I_image',I,'background_value',obj.background_value);
    

    
    
    
end