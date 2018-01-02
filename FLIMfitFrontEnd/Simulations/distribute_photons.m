function w = distribute_photons(n,p)

    p = p / sum(p);
    u = rand([n 1]);
    
    edges = [0 cumsum(p)];
    w = discretize(u,edges);
