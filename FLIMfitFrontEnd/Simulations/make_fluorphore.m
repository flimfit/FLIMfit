function f = make_fluorphore(tau,beta,Qavg,sigma,spectra)
    
    assert(sum(beta) == 1);
    taum = sum(tau.*beta);

    f.kf = Qavg / taum;
    f.knf = 1 ./ tau - f.kf;
    f.Q = f.kf .* tau;
    f.tau = tau;
    f.beta = beta;
    f.sigma = sigma;
    f.spectra = spectra / sum(spectra);

end