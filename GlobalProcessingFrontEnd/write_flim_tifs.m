function write_flim_tifs(folder,t,data)

    folder = ensure_trailing_slash(folder);

    sz = size(data);

    if ndims(data) == 4 && sz(2) == 1
        data = reshape(data,[sz(1) sz(3:end)]);
    end

    for i=1:length(t)
       
       plane = data(i,:,:);
       plane = squeeze(plane); 
       
       name = [folder 'T_' num2str(t(i),'%05d') '.tif'];
       
       imwrite(plane,name); 
        
    end

end