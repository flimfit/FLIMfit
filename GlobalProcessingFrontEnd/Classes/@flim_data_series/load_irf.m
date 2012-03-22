function load_irf(obj,file)

    if strcmp(obj.mode,'TCSPC')
        channel = obj.request_channels(obj.polarisation_resolved);
    else
        channel = 1;
    end

    % Get IRF data
    %if nargin < 2
    %    [t_irf,irf_image_data,~,name] = load_flim_file('Select a file from the IRF data set',[],channel);
    %else
    
    [t_irf,irf_image_data,~,name] = load_flim_file(file,channel);
    %end
        
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
     
    % Pick out peak section of IRF (section of IRF within 20dB of peak)   
    %[t_irf,irf,~] = pickOutIRF(t_irf,irf);
    
    %Remove 'background', set to minimum value of IRF
    %irf = double(irf - min(irf));
     
    irf = double(irf);
    
    obj.t_irf = t_irf(:);
    obj.irf = irf;
    obj.irf_name = name;

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    obj.estimate_irf_background();
    
    obj.compute_tr_irf();
    obj.compute_tr_data();
    
    notify(obj,'data_updated');

    
end