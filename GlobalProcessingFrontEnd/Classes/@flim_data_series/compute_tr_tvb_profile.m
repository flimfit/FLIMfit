function compute_tr_tvb_profile(obj)
    %> Calculate the transformed time varying background profile

    if obj.init
       
        % Downsample
        sel = 0:(length(obj.t)-1);
        sel = mod(sel,obj.downsampling) == 0;
        tr_t = obj.t(sel);
        
        % Crop based on limits
        t_inc = tr_t >= obj.t_min & tr_t <= obj.t_max;

        if ~isempty(obj.tr_t_irf)
            t_inc = t_inc & tr_t >= min(obj.tr_t_irf);
        end
        
        if size(obj.tvb_profile,1) ~= obj.n_t
            obj.tvb_profile = zeros(obj.n_t, obj.n_chan);
        end
        
        obj.tr_tvb_profile = double(obj.tvb_profile);
        
        sz = size(obj.tvb_profile);
        sz(1) = sz(1) / obj.downsampling;
        obj.tr_tvb_profile = reshape(obj.tr_tvb_profile,[obj.downsampling sz]);
        obj.tr_tvb_profile = nansum(obj.tr_tvb_profile,1);
        obj.tr_tvb_profile = reshape(obj.tr_tvb_profile,sz);

        % Subtract background and crop
        obj.tr_tvb_profile = obj.tr_tvb_profile(t_inc,:,:,:);

        % Scale the background based on the size of the smoothing kernel.
        % If we move away from square binning then this will need to be
        % changed. 
        obj.tr_tvb_profile = obj.tr_tvb_profile * obj.binning^2;

            
    end
end