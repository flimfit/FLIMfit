function load_tvb(obj,data_series,object)

    t_tvb = [];
    tvb_data = [];
    
    switch whos_Object(obj.session,object.getId().getValue());
        case 'Image'
            
            metadata = get_FLIM_params_from_metadata(obj.session,object.getId());
                        
            if isempty(metadata.n_channels) || metadata.n_channels > 1 strcmp(data_series.mode,'TCSPC')
                channel = data_series.request_channels(data_series.polarisation_resolved);
            else
                channel = 1;
            end;
            %
            if ~isempty(metadata.n_channels) && metadata.n_channels==metadata.SizeC && ~strcmp(metadata.modulo,'ModuloAlongC') %if native multi-spectral FLIM
                ZCT = [metadata.SizeZ channel metadata.SizeT]; 
            else
                ZCT = get_ZCT(object,metadata.modulo);
            end
            %
            try
                [t_tvb, tvb_data, ~] = obj.OMERO_fetch(object, channel, ZCT, metadata);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end      
                                    
        case 'Dataset'
            [t_tvb tvb_data] = obj.load_FLIM_data_from_Dataset(object);
            t_tvb = t_tvb';
        otherwise
            return;
    end
            
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
    if length(t_tvb)==length(data_series.t) && max(abs(t_tvb-data_series.t)) > 1
        warning('GlobalProcessing:ErrorLoadingTVB','Timepoints were different in TVB and data');
    end
    
    data_series.tvb_profile = tvb_data;
    data_series.compute_tr_tvb_profile();
    
    notify(data_series,'data_updated');
    
end