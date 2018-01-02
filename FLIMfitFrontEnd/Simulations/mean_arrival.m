function tm = mean_arrival(decay,system,channel)

    decay = decay(:,channel);    
    t = (0:(system.nbin-1))'*system.dt;    
    tm = sum(decay .* t) / sum(decay) - system.irf.centre;