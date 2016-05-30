function [irf_final,t_final] = FitGaussianIRF(td, d, T, ax)

    dt = td(2)-td(1);
    t = -max(td):1:max(td);
    decay_fcn = @(tau,t) ((t>=0) + 1 / (exp(T/tau)-1)) .* exp(-t/tau);

    dc = [];

    opts = optimset('Display', 'iter');

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
    
    %min_idx = find(irf_final >= max(irf_final)*1e-3,1) - 1;
    %irf_final = irf_final(min_idx:end);
    %t_final = t_final(min_idx:end);

    
    
    % Show new IRF
    plot(ax, td,[d-dc]);
    %hold on;
    %plot(ax, t_final, irf_final / max(irf_final));
    %hold off;


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
        dc = I * decay_fcn(tau, binned_t);
        dc = conv(binned_irf,dc,'same');
        dc = dc((end-length(td)+1):end);
        %dc = bin_decay(dc);
    end

    function [binned_decay, binned_t] = bin_decay(decay)
        tg = floor(t / dt);
        tgm = min(tg);
        binned_decay = accumarray(tg'-tgm+1,decay');
        binned_t = tgm*dt + (0:(length(binned_decay)-1)) * dt;
    end

end
