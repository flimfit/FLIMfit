function system = make_system

    system.irf.width = 150;
    system.irf.centre = 1000;
    system.trep = 12500;
    system.dt = 50;
    system.nbin = system.trep / system.dt;
    system.nchan = 3;
