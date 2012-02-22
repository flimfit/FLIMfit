function set_irf(obj,t_irf,irf)
    %> Set IRF from memory
    
    obj.t_irf = t_irf(:);
    obj.irf = irf(:);
    obj.irf_name = '';

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    obj.irf_background = min(obj.irf(:));
    
    obj.compute_tr_irf();
    
    notify(obj,'data_updated');
    
end