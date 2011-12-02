function load_data_series(obj,root_path,mode,polarisation_resolved,data_setting_file,selected,channel)   
    %> Load a series of FLIM data files
    
    if nargin < 7
        channel = [];
    end
    if nargin < 6
        selected = [];
    end
    if nargin < 5
        data_setting_file = [];
    end
    
    if ~exist(root_path,'dir')
        throw(MException('GlobalAnalysis:PathDoesNotExist','Path does not exist'));
    end
   
    root_path = ensure_trailing_slash(root_path);

    obj.root_path = root_path;
    obj.mode = mode;
    obj.polarisation_resolved = polarisation_resolved;
    
    if strcmp(mode,'TCSPC')

        if isempty(channel)
            channel = obj.request_channels(polarisation_resolved);
        end
        obj.channels = channel;
        
        files = [dir([root_path '*.sdt']); dir([root_path '*.txt'])];            
        num_datasets = length(files);
        
        file_names = cell(1,num_datasets);
        for i=1:num_datasets
            file_names{i} = files(i).name;
        end
        file_names = sort_nat(file_names);   
        
        if isempty(selected)
            [obj.file_names, ~, obj.lazy_loading] = dataset_selection(file_names);
        elseif strcmp(selected,'all')
            obj.file_names = file_names;
            obj.lazy_loading = false;
        else
            obj.file_names = file_names(selected);
            obj.lazy_loading = false;
        end
        
        num_datasets = length(obj.file_names);

        for i=1:num_datasets
            obj.file_names{i} = [root_path obj.file_names{i}];
        end
        
        % open first file
        [obj.t,data] = open_flim_files([],obj.file_names{1},channel);         
        data_size = size(data);
        
        % if only one channel reshape to include singleton dimension
        if length(data_size) == 3
            data_size = [data_size(1) 1 data_size(2:3)];
        end
        
        clear data;
        
        obj.data_size = data_size;
        obj.num_datasets = num_datasets;
        
        %set names
        obj.names = cell(1,num_datasets);
        for j=1:num_datasets
            [~,name,~] = fileparts(obj.file_names{j});
            obj.names{j} = name;
        end
        
    else % widefield
        
        contents = dir(root_path);

        % Get children of root path which are directories
        folders = [];
        for j=1:length(contents)
            if contents(j).isdir && contents(j).name(1) ~= '.'
                folders = [folders contents(j)];
            end
        end
        
        num_datasets = length(folders);
        
        folder_names = cell(1,num_datasets);
        for i=1:num_datasets
            folder_names{i} = folders(i).name;
        end
        
        folder_names = sort_nat(folder_names);    
        
        if isempty(selected)
            [folder_names, ~, obj.lazy_loading] = dataset_selection(folder_names);
        elseif strcmp(selected,'all')
            obj.lazy_loading = false;
        else
            folder_names = folder_names(selected);
            obj.lazy_loading = false;
        end
        
        num_datasets = length(folder_names);
        
        % Load first folder to get sizes etc.
        first_root = [root_path folder_names{1}];
        first_file = get_first_file(first_root);

        [~, first_file_name, ext] = fileparts(first_file);
        
        file_names = cell(length(folder_names),1);
        for i=1:length(folder_names)
            file_names{i} = [root_path folder_names{i} filesep first_file_name ext];
        end
        obj.file_names = file_names;
        
        [obj.t,data] = open_flim_files([],first_file); 
        data_size = size(data);

        % if only one channel reshape to include singleton dimension
        if length(data_size) == 3
            data_size = [data_size(1) 1 data_size(2:3)];
        end
        
        clear data;

        obj.data_size = data_size;
        obj.num_datasets = num_datasets;       

        %set names
        obj.names = cell(1,num_datasets);

        for j=1:num_datasets
            obj.names{j} = folder_names{j};
        end
    end    
   
    obj.metadata = extract_metadata(obj.names);
       
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.num_datasets);
    end
    
    obj.init_dataset(data_setting_file);
    
end