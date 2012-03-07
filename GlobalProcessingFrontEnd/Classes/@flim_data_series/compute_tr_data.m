function calculated = compute_tr_data(obj,notify_update)
    %> Transform data based on settings
    
    if nargin < 2
        notify_update = true;
    end
   
    
    calculated = false;
    
    if obj.init && ~obj.suspend_transformation

        calculated = true;
         
        % Display popup window if requested
        if obj.use_popup && ~obj.lazy_loading
            wait_handle = waitbar(0,'Transforming Data...');
        end

        % Select points to use if downsampling 
        sel = 0:(length(obj.t)-1);
        sel = mod(sel,obj.downsampling) == 0;
        obj.tr_t = obj.t(sel);

        % Crop timegates
        t_inc = obj.tr_t >= obj.t_min & obj.tr_t <= obj.t_max;

        % If there is a IRF ensure that we don't have data points before the IRF
        if ~isempty(obj.tr_t_irf)
            t_inc = t_inc & obj.tr_t >= min(obj.tr_t_irf);
        end
        
        % For polarisation resolved data, attempt to line up the two
        % polarisation channels to within a timegate. This allows the user
        % to sensibly crop the data
        dt = obj.t(2) - obj.t(1);
        coarse_shift = round(obj.irf_perp_shift/dt);        
        
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
        
        % Apply all the masking above
        obj.tr_t = obj.tr_t(t_inc);
        
        % Now set the data size
        obj.set_tr_data_size([length(obj.tr_t) obj.n_chan obj.height obj.width]);

        % Determine which datasets we have actively loaded in memory
        loaded_idx = 1:obj.num_datasets;
        loaded_idx = loaded_idx(logical(obj.loaded));
        
        % If we're storing directly memory make sure we clear it first as
        % it may be differently shaped to the old data
        if ~obj.use_memory_mapping
            obj.tr_data_series_mem = [];
        end
        
        bg = obj.background;
        
        % Cycle through the loaded datasets and apply transformations
        for i = 1:length(loaded_idx)  
            
            % Switch the data and transformed data into memory, the current 
            % dataset will then reside in obj.data_series and obj.tr_data_series
            obj.switch_active_dataset(loaded_idx(i));
            obj.tr_data_series = double(obj.data_series);
            
            % Downsample the data
            sz = size(obj.tr_data_series);
            sz(1) = sz(1) / obj.downsampling;
            obj.tr_data_series = reshape(obj.tr_data_series,[obj.downsampling sz]);
            obj.tr_data_series = nansum(obj.tr_data_series,1);
            obj.tr_data_series = reshape(obj.tr_data_series,sz);
            
            % Subtract background and crop
            if length(bg) == 1 || all(size(bg)==size(obj.tr_data_series))
                obj.tr_data_series = obj.tr_data_series - double(bg);
            end
            
            % Shift the perpendicular channel
            tmp = obj.tr_data_series(t_inc,1,:,:);
            if obj.polarisation_resolved
                tmp(:,2,:,:) = obj.tr_data_series(t_inc_perp,2,:,:);
            end
            obj.tr_data_series = tmp;
                
            
            % Bin data
            if obj.binning > 1
                obj.tr_data_series = obj.smooth_flim_data(obj.tr_data_series,obj.binning);
            end


            % Set transformed data to memory or the memory mapped object
            if obj.use_memory_mapping
                % If we're on WIN32 then we only have one dataset loaded at
                % a time, otherwise all are loaded and we need to specify
                % which repeat (i.e. dataset we are accessing). Hence
                % Data(1) or Data(i).
                if ~is64
                    obj.tr_memmap.Data(1).data_series = obj.tr_data_series;
                else
                    obj.tr_memmap.Data(i).data_series = obj.tr_data_series;
                end
            else
                obj.tr_data_series_mem(:,:,:,:,i) = obj.tr_data_series;
            end
            
            % Update the waitbar
            if obj.use_popup && ~obj.lazy_loading
                waitbar(i/obj.n_datasets,wait_handle);
            end
        end

        obj.compute_tr_irf();
        obj.compute_intensity();
        obj.compute_tr_tvb_profile();
        
        % Close the popup window
        if obj.use_popup && ~obj.lazy_loading
            close(wait_handle);
        end
        
        if notify_update
            notify(obj,'data_updated');
        end
    end
end