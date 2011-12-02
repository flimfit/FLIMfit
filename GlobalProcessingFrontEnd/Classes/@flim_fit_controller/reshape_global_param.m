function param = reshape_global_param(obj,param)

    n_group = length(obj.n_regions);

    ret_param = cell([1 n_group]);

    r_start = 1;   
    for i=1:n_group
        r_next = r_start + obj.n_regions(i);
            
        ret_param{i} = param(:,r_start:(r_next-1));
            
        r_start = r_next;
    end

end