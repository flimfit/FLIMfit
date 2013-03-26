
function [data, row_headers] = get_table_data(obj, stat)

    if nargin == 1
        stat = [];
    end

    r = obj.fit_result;
    % Column Headers
    % -------------------
    %if p.global_fitting == 0 && ~obj.bin
        row_headers = {'im_group'; 'region'; 'success %'; 'iterations'; 'pixels'};
    %else
    %    column_headers = {'im_group'; 'region'; 'return code'; 'iterations'; 'pixels'};
    %end

    param_names = r.fit_param_list();

    if isempty(stat)
        
        stats = r.stat_names;
        n_stats = length(stats);
        n_params = length(param_names);
        
        stats = repmat(stats,[n_params 1]);
        param_names = repmat(param_names,[1 n_stats]);
        
        stats = stats(:);
        param_names = param_names(:);
        
        stats = cellfun(@(a)cat(2,a,' - '),stats,'UniformOutput',false);
        param_names = cellfun(@(a,b)cat(2,a,b),stats,param_names,'UniformOutput',false);
    end
    
    row_headers = [row_headers; param_names(:)];

    
    
    data = [];
    for i=1:length(r.regions)

        if ~isempty(r.regions{i})
        
            im = r.image(i);
            regions = r.regions{i};
            n_regions = length(regions);
            im = repmat(im,[1,n_regions]);
            success = r.success{i};
            iterations = r.iterations{i};
            pixels = r.region_size{i};

            if isempty(stat)
                row = [];
                for j=1:length(r.stat_names)
                    row = [row; r.region_stats{i}.(r.stat_names{j})];
                end
            else
                row = r.region_stats{i}.(stat);
            end

            col = [im; double(regions); success; iterations; pixels; row]; 

            data = [data col];
        end
    end

end
