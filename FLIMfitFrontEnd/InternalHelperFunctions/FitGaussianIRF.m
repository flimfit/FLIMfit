function [irf_final,t_final] = FitGaussianIRF(td, d, T, ax)

    dt = td(2)-td(1);
    t = -max(td):1:max(td);
    dc = [];

    opts = optimset('Display', 'iter', 'MaxFunEvals', 1000);

    tau0 = 4000;
    sigma0 = 200;

    [I0,idx] = max(d);
    t0 = td(idx) - sigma0;

    count = 0;
    x = fminsearch(@fit, [tau0, t0, sigma0, I0, 0], opts);
    
    % Display Results
    disp(['t0: ' num2str(x(2)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);

    irf_final = irfc;
    t_final = irft;    

    function r = fit(x)
        tau = x(1);
        t0 = x(2);
        sigma = x(3);
        I = x(4);
        offset = x(5);
        [dc,irfc,irft] = generate_decay(I, tau, t0, sigma, offset);
        
        if mod(count,20) == 0
            plot(td,d,'ob','MarkerSize',3);
            hold on;
            plot(td,dc,'-b');
            plot(irft,irfc/max(irfc)*max(d),'r');
            xlim([min(td),max(td)])
            drawnow
            hold off;
        end
        count = count + 1;
        r = sum((d-dc).^2);
    end

    function [dc,binned_irf,binned_t] = generate_decay(I, tau, t0, sigma, offset)
        irf = normpdf(t,t0,sigma) + offset;
        [binned_irf, binned_t] = bin_decay(irf);
        dc = I * conv_irf(binned_t,binned_irf,tau);
        dc = dc((end-length(td)+1):end);
    end

    function [binned_decay, binned_t] = bin_decay(decay)
        tg = ceil(t / dt);
        tgm = min(tg);
        binned_decay = accumarray(tg'-tgm+1,decay');
        binned_t = tgm*dt + (0:(length(binned_decay)-1))' * dt;
    end

    function D = conv_irf(tg,g,tau)
       
        % See thesis page: 69-70
        
        rhoi = exp(tg/tau);
        G = g.*rhoi;
        G = cumsum(G);
        G = circshift(G,1);
        G(1) = 0;
        rho = exp(dt / tau);
        
        A = tau.^2/dt * (1-rho)^2/rho;
        B = tau.^2/dt * (dt / tau - 1 + 1/rho);
        
        C = A * G + B * g .* rhoi;
        
        f = 1 / (exp(T/tau)-1);
        
        D = (C + f * C(end))./ rhoi / tau * dt;
        
    end

end
