function load_irf_from_Dataset(obj,data_series,dataset,load_as_image)

    [t_irf im_data] = obj.load_FLIM_data_from_Dataset(dataset);                                
    %
    irf_image_data = double(im_data);
    
    % Sum over pixels
    s = size(irf_image_data);
    if length(s) == 3
        irf = reshape(irf_image_data,[s(1) s(2)*s(3)]);
        irf = mean(irf,2);
    elseif length(s) == 4
        irf = reshape(irf_image_data,[s(1) s(2) s(3)*s(4)]);
        irf = mean(irf,3);
    else
        irf = irf_image_data;
    end
    
    % export may be in ns not ps.
    if max(t_irf) < 300
       t_irf = t_irf * 1000; 
    end
    
    if load_as_image
        irf_image_data = data_series.smooth_flim_data(irf_image_data,7);
        data_series.image_irf = irf_image_data;
        data_series.has_image_irf = true;
    else
        data_series.has_image_irf = false;
    end
        
    data_series.t_irf = t_irf(:);
    data_series.irf = irf;
    data_series.irf_name = 'irf';

    data_series.t_irf_min = min(data_series.t_irf);
    data_series.t_irf_max = max(data_series.t_irf);
    
    data_series.estimate_irf_background();
    
    data_series.compute_tr_irf();
    data_series.compute_tr_data();
    
    notify(data_series,'data_updated');
    
end