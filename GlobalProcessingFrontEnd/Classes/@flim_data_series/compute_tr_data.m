function calculated = compute_tr_data(obj,notify_update)
    %> Transform data based on settings
    
    if nargin < 2
        notify_update = true;
    end
   
    
    calculated = false;
    
    if obj.init && ~obj.suspend_transformation

        calculated = true;

        % Crop timegates
        t_inc = obj.t >= obj.t_min & obj.t <= obj.t_max;
        

        % If there is a IRF ensure that we don't have data points before the IRF
        if ~isempty(obj.tr_t_irf)
            t_inc = t_inc & obj.t >= min(obj.tr_t_irf);
        end
        
        % For polarisation resolved data, attempt to line up the two
        % polarisation channels to within a timegate. This allows the user
        % to sensibly crop the data
        if length(obj.t) > 1
            dt = obj.t(2) - obj.t(1);
            coarse_shift = round(obj.irf_perp_shift/dt);      
        else
            coarse_shift = 0;
        end
        
        if coarse_shift < 0
           t_inc(end+coarse_shift:end) = 0;            
        elseif coarse_shift > 0
           t_inc(1:coarse_shift) = 0; 
        end
        
        t_inc_perp = circshift(t_inc,[1 -coarse_shift]);

        % If shifting the perp channel pushes us over the edge crop both 
        % data channels
        if sum(t_inc_perp) < sum(t_inc)
            if obj.irf_perp_shift < 0
               n = find(t_inc_perp, 1, 'first') - 2;
               t_inc(end-n:end) = 0;             
            else
               n = length(t_inc_perp) - find(t_inc_perp, 1, 'last');
               t_inc(1:n) = 0;
            end
        end
        
        obj.t_skip = [find(t_inc,1,'first') find(t_inc_perp,1,'first')]-1;
        
        % Apply all the masking above
        obj.tr_t = obj.t(t_inc);
        obj.tr_t_int = obj.t_int(t_inc);

            
        obj.cur_tr_data = double(obj.cur_data);
        
        % Subtract background and crop
        bg = obj.background;
        if length(bg) == 1 || all(size(bg)==size(obj.cur_tr_data))
            obj.cur_tr_data = obj.cur_tr_data - double(bg);
        end
        
        if true || strcmp(obj.mode,'TCSPC') || obj.n_t == 1
            in = sum(obj.cur_tr_data,1);
        else
            in = trapz(obj.t,obj.cur_tr_data,1)/1000;
        end

        if obj.polarisation_resolved
            in = in(1,1,:,:) + 2*obj.g_factor*in(1,2,:,:);
        end
        
        obj.intensity = squeeze(in);

        % Shift the perpendicular channel
        tmp = obj.cur_tr_data(t_inc,1,:,:);
        if obj.polarisation_resolved
            tmp(:,2,:,:) = obj.cur_tr_data(t_inc_perp,2,:,:);
        end
        obj.cur_tr_data = tmp;


        % Smooth data
        if obj.binning > 0
            obj.cur_tr_data = obj.smooth_flim_data(obj.cur_tr_data,obj.binning);
        end

        obj.compute_tr_irf();
        obj.compute_intensity();
        obj.compute_tr_tvb_profile();
        
        if notify_update
            notify(obj,'data_updated');
        end
    end
end