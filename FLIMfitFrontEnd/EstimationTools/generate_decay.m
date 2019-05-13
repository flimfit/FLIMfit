function decay = generate_decay(t, T, tau, irf)

    if isa(irf,'analytical_irf')
    
        mu = irf.gaussian_parameters(1).mu;
        sigma = irf.gaussian_parameters(1).sigma;
        decay = generate_decay_analytical_irf(t, T, tau, mu, sigma);
    
    elseif isa(irf,'measured_irf')
       
        assert(all(t == irf.t));
        tr_irf = irf.irf;
        decay = generate_decay_measured_irf(t, T, tau, tr_irf);
        
    end
    
end
