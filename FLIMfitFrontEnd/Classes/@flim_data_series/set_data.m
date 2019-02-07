function load_data(obj, t, data, varargin)

    p = inputParser;
    p.addOptional('polarisation_resolved', false);
    p.addOptional('names', []);
    p.addOptional('mode', 'TCSPC');
    p.addOptional('metadata',[])
    p.parse(varargin{:});
    
    polarisation_resolved = p.Results.polarisation_resolved;
    names = p.Results.names;
    mode = p.Results.mode;
    metadata = p.Results.metadata;
    
    data = obj.ensure_correct_dimensionality(data);   
    n_datasets = size(data,5);
    
    if isempty(names)
        names = strcat({'Image'},num2str(1:n_datasets));
    else
        assert(numel(names)==n_datasets);
    end
    
    obj.names = names;
    obj.lazy_loading = false;
    obj.n_datasets = n_datasets;
    obj.polarisation_resolved = polarisation_resolved;
    obj.metadata = metadata;
    
    obj.use_memory_mapping = false;
    obj.loaded = ones([1 obj.n_datasets]);    
    obj.data_series_mem = data;
    
    obj.t = t;
    obj.data_size = size(data);
    obj.n_chan = size(data,2);
    obj.mode = mode;
    obj.data_type = class(data);
    obj.channels = 1:obj.n_chan;
    
    obj.switch_active_dataset(1);
    obj.init_dataset();

end