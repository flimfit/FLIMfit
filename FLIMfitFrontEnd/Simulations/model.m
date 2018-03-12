function total_decay = model(D, A, kt0, mode, system)

    if strcmp(mode,'static')
        f = linspace(0,4,100);
        f = reshape(f,[1 1 length(f)]);
        p = kappa_factor_pdf(f);        
        f = f + 0.5 * (f(2)-f(1));
    else
        f = (2/3)^2;
        p = 1;
    end
    
    mu = system.irf.centre;
    sigma = system.irf.width;
    
    dt = system.dt;
    T = system.trep;
    
    t = (0:(system.nbin-1))'*dt;
    
    total_decay = 0;
    
    for i=1:length(D.Q)  
        kt = kt0 * f;
        tauT = 1 ./ kt;
        tauDf = 1 ./ (1./D.tau(i) + 1./tauT);

        astar = kt ./ (1./D.tau(i) + kt - 1/A.tau);
        donor = D.sigma .* D.Q(i) ./ D.tau(i) .* expC(t, tauDf) .* D.spectra;
        sens_acceptor = D.sigma .* astar .* A.Q ./ A.tau .* (expC(t, A.tau) - expC(t, tauDf)) .* A.spectra;
        direct_acceptor = A.sigma * A.Q ./ A.tau .* expC(t, A.tau) .* A.spectra;
        
        decay = donor + sens_acceptor + direct_acceptor;
        decay = p .* decay;
        decay = sum(decay,3) * dt;
        total_decay = total_decay + D.beta(i) * decay;
    end
    
    % Written as Fereidouni 2014, equiv to above
    % k = D.tau ./ tauDf - 1;
    % donor = D.sigma .* D.Q .* exp(-t ./ tauDf) ./ D.tau .* D.spectra;
    % sens_acceptor = D.sigma .* k ./ (A.tau - D.tau + k * A.tau) .* A.Q .* (exp(-t ./ A.tau) - exp(-t ./ tauDf)) .* A.spectra;
        
    
    function h = H(t, tau) 
        a = 1 / (sqrt(2) * sigma);
        b = (sigma^2 ./ tau + mu) * a;
        c = (erf(b - T * a) - exp(T./tau) .* erf(b)) ./ (exp(T./tau) - 1);
        d = 0.5 * tau .* exp(0.5*(sigma./tau).^2+mu./tau);
        
        P = 0.5 * erf(a.*(t-mu));
        Q = erf(b-t.*a);
        R = exp(-t./tau);
        
        h = tau .* P + d .* R .* (Q + c);        
    end
        
    function v = expC(t, tau)
        v = (H(t+dt, tau) - H(t, tau))/dt;
    end
end