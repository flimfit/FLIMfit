function decay = measure(t,w,system)

    t = t + normrnd(system.irf.centre,system.irf.width,size(t));
    t = mod(t,system.trep);
    t = ceil(t / system.dt);

    decay = accumarray([t w],1,[system.nbin system.nchan]);
    