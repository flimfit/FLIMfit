function emission = simulate(D, A, kt0, mode, system, n_photon)

    emission = 0;
    
    nd = length(D.tau);
    
    n_donor = binornd(n_photon,D.sigma/(D.sigma + A.sigma));
    n_acceptor = n_photon - n_donor;

    n_donor = mnrnd(n_donor,D.beta);
    
    pA = [A.kf A.knf];
    pA = pA / sum(pA);
    
    for i=1:nd       
        
        if strcmp(mode,'static')
            kt = kt0 * make_random_kappa_factor([n_donor(i) 1]);
        else
            kt = kt0 * (2/3)^2 * ones([n_donor(i) 1]);
        end
        
        fret_occurred = logical(binornd(1,kt ./ (kt + D.kf + D.knf(i))));
                
        % Donor 
        kt_donor = kt(~fret_occurred);
        emit = logical(binornd(1,D.kf ./ (D.kf + D.knf(i)),size(kt_donor)));
        kt_donor = kt_donor(emit);
        tauDf = donor_lifetime(D,i,kt_donor);
        
        t = exprnd(tauDf);
        w = distribute_photons(length(kt_donor), D.spectra);
        emission = emission + measure(t,w,system);

        % Sensitised acceptor
        kt_acceptor = kt(fret_occurred);
        emit = logical(binornd(1,A.kf ./ (A.kf + A.knf),size(kt_acceptor)));
        kt_acceptor = kt_acceptor(emit);
        tauDf = donor_lifetime(D,i,kt_acceptor);

        t = exprnd(tauDf) + exprnd(A.tau,size(tauDf));
        w = distribute_photons(length(kt_acceptor), A.spectra);
        emission = emission + measure(t,w,system);
        
    end
    
    % Direct acceptor
    n = mnrnd(n_acceptor,pA);
    n_direct_acceptor_emission = n(1);
    
    t = exprnd(A.tau,[n_direct_acceptor_emission 1]);
    w = distribute_photons(n_direct_acceptor_emission, A.spectra);
    emission = emission + measure(t,w,system);
