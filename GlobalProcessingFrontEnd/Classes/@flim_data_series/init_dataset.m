function init_dataset(obj,setting_file_name)
    %> Initalise dataset after we've loaded in the data
    
    % Set defaults for background depending on type of data
    if strcmp(obj.mode,'widefield') 
        obj.background_value = 200;
        obj.background_type = 1;
    else
        obj.background_value = 0;
        obj.background_type = 0;
    end
    
    obj.background_image = ones([obj.n_chan obj.height obj.width]) * obj.background_value;
    
    obj.mask = ones([obj.height obj.width obj.n_datasets],'uint8');
    obj.seg_mask = [];
    
    obj.intensity = [];
    obj.mask = [];
    obj.thresh_mask = [];
    obj.seg_mask = [];

    obj.use = true(obj.n_datasets,1);
    
    obj.binning = 1;
    obj.thresh_min = 1;
    obj.thresh_max = 1e10;
    
    obj.t_min = min(obj.t);
    obj.t_max = max(obj.t);   
    
    obj.t0 = 0;
    
    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    obj.irf_background = 0;
        
    if obj.polarisation_resolved
        obj.n_chan = 2;
    else
        obj.n_chan = 1;
    end
    
    % Reshape data to so 2nd dimension is polarisation channel
    s = size(obj.data_series);
    if length(s) == 3
        obj.data_series = reshape(obj.data_series,[s(1) 1 s(2) s(3)]);
    end
    
    obj.data_size = size(obj.data_series);
    obj.data_size = [obj.data_size ones(1,4-length(obj.data_size))];

    % If a data setting file exists load it
    if nargin < 2 || isempty(setting_file_name)
        if obj.polarisation_resolved
            setting_file_name = [obj.root_path 'polarisation_data_settings.xml'];
        else
            setting_file_name = [obj.root_path 'data_settings.xml'];
        end
    end
    
    if exist(setting_file_name,'file')
       obj.load_data_settings(setting_file_name); 
    end
    
    obj.init = true;
    
    obj.compute_tr_data();

end