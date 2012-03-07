function fetchirf_TCSPC(obj, image_descriptor, polarisation_resolved, channel)
    %> Load a single FLIM dataset
    
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        channel = [];
    end

    
    try
        [t_irf, irf_image_data] = OMERO_fetch(image_descriptor, channel, name);
    catch err
        
         rethrow(err);
    end
      
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
   
    
    obj.t_irf = t_irf(:);
    obj.irf = irf;
    obj.irf_name = name;

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    %obj.irf_background = min(obj.irf(:));
    
    obj.compute_tr_irf();
    obj.compute_tr_data();
    
    notify(obj,'data_updated');
   
  

end