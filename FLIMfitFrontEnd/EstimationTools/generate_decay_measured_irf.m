function decay = generate_decay_measured_irf(t, irf, T, tau)

    % Convolve exponential decay with lifetime tau with measured irf given
    % repetition rate T using trapezium integration across irf
    % See Warren thesis page: 69-70

    dt = t(2) - t(1);


    rhoi = exp(t/tau);
    G = irf.*rhoi;
    G = cumsum(G);
    G = circshift(G,1);
    G(1) = 0;
    rho = exp(dt / tau);

    A = tau.^2/dt * (1-rho)^2/rho;
    B = tau.^2/dt * (dt / tau - 1 + 1/rho);

    C = A * G + B * irf .* rhoi;

    f = 1 / (exp(T/tau)-1);

    decay = (C + f * C(end))./ rhoi / tau * dt;
    
end
