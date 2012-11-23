function load_tvb(obj,file)

    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xml')
       
        marshal_object(file,'flim_data_series',obj);
    
    else

        if strcmp(obj.mode,'TCSPC')
            channel = obj.request_channels(obj.polarisation_resolved);
        else
            channel = 1;
        end

        [t_tvb,tvb_data] = load_flim_file(file,channel);    
        tvb_data = double(tvb_data);

        % Sum over pixels
        s = size(tvb_data);
        if length(s) == 3
            tvb_data = reshape(tvb_data,[s(1) s(2)*s(3)]);
            tvb_data = mean(tvb_data,2);
        elseif length(s) == 4
            tvb_data = reshape(tvb_data,[s(1) s(2) s(3)*s(4)]);
            tvb_data = mean(tvb_data,3);
        end

        % export may be in ns not ps.
        if max(t_tvb) < 300
           t_tvb = t_tvb * 1000; 
        end

        % check we have all timepoints
        if length(t_tvb)==length(obj.t) && max(abs(t_tvb-obj.t)) > 1
            warning('GlobalProcessing:ErrorLoadingTVB','Timepoints were different in TVB and data');
        end

        obj.tvb_profile = tvb_data;
    end
    
    obj.compute_tr_tvb_profile();
    
    notify(obj,'data_updated');

    
end