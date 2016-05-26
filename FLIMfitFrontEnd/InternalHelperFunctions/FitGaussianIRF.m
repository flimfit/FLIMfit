function [irf_final,t_final] = FitGaussianIRF(td, d, T, ax)

    dt = td(2)-td(1);
    t = -max(td):1:max(td);
    decay_fcn = @(tau,t) ((t>0) + 1 / exp(T/tau)) .* exp(-t/tau);

    sel = ismember(int32(t), int32(td));
    sum(sel)
    dc = [];

    opts = optimset('Display', 'iter');

    [I0,idx] = max(d);
    t0 = td(idx);

    tau0 = 4000;
    sigma0 = 200;

    count = 0;
    x = fminsearch(@fit, [tau0, t0, sigma0, I0], opts);

    disp(['t0: ' num2str(x(2)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);

    tg = floor(t / dt);
    tgm = min(tg);
    irf_final = accumarray(tg'-tgm+1,irfc');
    t_final = tgm*dt + (0:(length(irf_final)-1)) * dt;

    min_idx = find(irf_final > 1e-3,1) - 1;
    irf_final = irf_final(min_idx:end);
    t_final = t_final(min_idx:end);

    plot(ax, td,[d dc]);
    hold on;
    plot(ax, t_final, irf_final / max(irf_final));
    hold off;


    function r = fit(x)
        tau = x(1);
        t0 = x(2);
        sigma = x(3);
        I = x(4);
        [dc,irfc] = generate_decay(I, tau, t0, sigma, 0, 0);
        
        if mod(count,20) == 0
            plot(td,d,'ob','MarkerSize',3);
            hold on;
            plot(td,dc,'-b');
            plot(t,irfc/max(irfc)*max(d),'r');
            xlim([min(td),max(td)])
            drawnow
            hold off;
        end
        count = count + 1;
        r = sum((d-dc).^2);
    end

    function [dc,irf] = generate_decay(I, tau, t0, sigma, offset)
        irf = normpdf(t,t0,sigma) + offset;
        
        dc = I * decay_fcn(tau, t);
        dc = conv(dc,irf,'same');
        dc = dc(1:length(t));
        
        dc = dc(sel)';
    end

end
