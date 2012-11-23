function irf_data = generate_t0_map(obj, mask, dataset)

    decay = obj.get_roi(mask, dataset);
    decay = mean(decay,3);
    decay(decay<0) = 0;
    n = 4;
    nt = 5;
    
    diff = zeros(obj.height/n,obj.width/n);
    sim = zeros(obj.height/n,obj.width/n);
    
    ti = obj.tr_t;
    tii = min(ti):nt:max(ti);
    
    decayi = interp1(ti,decay,tii);
    
    h=waitbar(0,'Calculating offsets');
    for i=1:(obj.width/n)
        for j=1:(obj.height/n)
            
            decayij = obj.cur_tr_data(:,:,j*n,i*n);   
            decayij(decayij<0) = 0;
            decayiji = interp1(ti,decayij,tii);
            
            [a,lags] = xcorr(decayi,decayiji,200/nt);
            [m,idx] = max(a);
            sim(j,i) = m;
            diff(j,i) = lags(idx)*nt;
            
        end
        if mod(i,20)
            waitbar(i/obj.width*n,h);
        end
    end
    close(h);
    diff = imresize(diff,n,'nearest');
    
    f=figure('Units','Pixels');
    p = get(f,'Position');
    p(2:4) = [200,400,600];
    set(f,'Position',p);
    
    subplot(2,1,1);
    plot(obj.tr_t,decay);
    
    subplot(2,1,2);
    imagesc(diff);
    daspect([1,1,1]);
    colorbar
    
    irf_data = struct('t_irf',obj.tr_t,'irf',decay,'t0_image',diff);
    

    
    
    
end