function conv_decay = model(D, A, kt0, mode, system)

    if strcmp(mode,'static')
        f = linspace(0,4,100);
        f = f(2:end);
        f = reshape(f,[1 1 length(f)]);
        p = kappa_factor_pdf(f);
    else
        f = (2/3)^2;
        p = 1;
    end
    
    dt = 1;
    
    t = (1:dt:system.trep)'-1;
    
    kt = kt0 * f;
    tauT = 1 ./ kt;
    tauDf = 1 ./ (1/D.tau + 1./tauT);
    
    astar = kt ./ (1/D.tau + kt - 1/A.tau);
    donor = D.sigma .* D.Q ./ D.tau .* exp(-t ./ tauDf) .* D.spectra;
    sens_acceptor = D.sigma .* astar .* A.Q ./ A.tau .* (exp(-t ./ A.tau) - exp(-t ./ tauDf)) .* A.spectra;
    direct_acceptor = A.sigma * A.Q ./ A.tau .* exp(-t ./ A.tau) .* A.spectra;
    
    % Written as Fereidouni 2014, equiv to above
    % k = D.tau ./ tauDf - 1;
    % donor = D.sigma .* D.Q .* exp(-t ./ tauDf) ./ D.tau .* D.spectra;
    % sens_acceptor = D.sigma .* k ./ (A.tau - D.tau + k * A.tau) .* A.Q .* (exp(-t ./ A.tau) - exp(-t ./ tauDf)) .* A.spectra;

    
    decay = donor + sens_acceptor + direct_acceptor;
    decay = p .* decay;
    decay = sum(decay,3) * dt;
    
    irf = normpdf(t,system.irf.centre,system.irf.width);
    
    for i=1:size(decay,2)   
        conv_decay(:,i) = conv(decay(:,i),irf);
    end
    conv_decay = conv_decay(1:length(t),:);
    
    conv_decay = reshape(conv_decay,[system.dt, system.nbin, system.nchan]);
    conv_decay = sum(conv_decay,1);
    conv_decay = squeeze(conv_decay);
    