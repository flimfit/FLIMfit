function load_single(obj,file,polarisation_resolved,data_setting_file,channel)
    %> Load a single FLIM dataset
    
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        data_setting_file = [];
    end
    if nargin < 5
        channel = [];
    end
    
    [path,name,ext] = fileparts(file);
    obj.root_path = ensure_trailing_slash(path);    
    
    % Determine which channels we need to load 
    if (strcmp(ext,'.sdt') || strcmp(ext,'.txt')) && isempty(channel)
        if polarisation_resolved
            channel = obj.request_channels(polarisation_resolved);
        else
            [n_channels_present channel_info] = obj.get_channels(file);
            if n_channels_present > 1
                [obj.names,channel] = dataset_selection(channel_info);
                obj.load_multiple_channels = true;
            else 
                channel = 1;
            end
        end
    end
    
    % Load data file
    [obj.t,data,obj.t_int] = load_flim_file(file,channel);
    
    if strcmp(ext,'.sdt') || strcmp(ext,'.txt') || strcmp(ext,'.irf') 
        obj.mode = 'TCSPC';
    end
    
    obj.file_names = {file};
    obj.channels = channel;
    
    if isempty(obj.names)
        % Set names from file names
        if strcmp(ext,'.sdt') || strcmp(ext,'.txt') || strcmp(ext,'.irf') 
            if isempty(obj.names)    
                obj.names{1} = name;
            end
        else
            path_parts = split(filesep,path);
            obj.names{1} = path_parts{end};
        end
    end
    
    obj.num_datasets = length(obj.names);
    
    obj.polarisation_resolved = polarisation_resolved;
   
    data = obj.ensure_correct_dimensionality(data);
    obj.data_size = size(data);
    
    if obj.load_multiple_channels
        obj.data_size(5) = obj.data_size(2);
        obj.data_size(2) = 1;
    end
    
       
    obj.metadata = extract_metadata(obj.names);
    
    obj.load_selected_files();
        
    obj.init_dataset(data_setting_file);

end