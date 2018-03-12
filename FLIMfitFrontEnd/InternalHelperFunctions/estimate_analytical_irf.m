function [analytical_params,chi2_final] = estimate_analytical_irf(t, decay, T, fit_ax, res_ax)
        
    dt = t(2)-t(1);
    dvalid = decay > 0;
    
    t_irf = min(t):25:max(t);
    
    opts = optimset('MaxFunEvals', 10000);

    tau0 = 4000;
    sigma0 = 300;

    [~,idx] = max(decay);
    t0 = t(idx) - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, t0, sigma0, 1e-1], opts);
    
    count = 0;
    fit(x);
    
    analytical_params.sigma = x(3);
    analytical_params.mu = x(2);
    analytical_params.offset = 0;
    
    % Display Results
    disp(['t0: ' num2str(x(2)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);
    disp(['tau: ' num2str(x(1)) ' ps']);
    disp(['offset: ' num2str(x(4))]);
    
    function chi2 = fit(x)
        tau = x(1);
        t0 = x(2);
        sigma = x(3);
        offset = x(4);
        I = 1;
        
        [analytical_decay,irf] = generate_decay(I, tau, t0, sigma, offset);
        
        I = analytical_decay \ decay;
        analytical_decay = I * analytical_decay;
        
        n_free = length(decay) - length(x);

        % Use maximum likelihood estimator
        A = decay(dvalid) .* log(analytical_decay(dvalid)./decay(dvalid));
        chi2 = -2 * ( sum(decay-analytical_decay) + sum(A)) / n_free;
        
        if mod(count,500) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            plot(fit_ax,t,decay,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,t,analytical_decay,'-b');
            plot(fit_ax,t_irf,irf/max(irf)*max(decay),'r');
            xlim(fit_ax,[min(t),max(t)])
            ylim(fit_ax,[0 1.2*max(decay)])
            hold(fit_ax,'off');
            set(fit_ax,'Box','off','TickDir','out')
            xlabel(fit_ax,'Time (ps)');
            ylabel(fit_ax,'Intensity');
            text(fit_ax,max(t),1.2*max(decay),label,'HorizontalAlignment','right','FontSize',12,'BackgroundColor',label_color);
            
            plot(res_ax,t,(decay-analytical_decay)./sqrt(decay)/n_free,'b');
            set(res_ax,'Box','off','TickDir','out')
            xlim(res_ax,[min(t),max(t)])
            drawnow
        end
        count = count + 1;
    end

    function h = H(t, tau, mu, sigma)        
        a = 1 / (sqrt(2) * sigma);
        b = (sigma^2 / tau + mu) * a;
        c = (erf(b - T * a) - exp(T/tau) * erf(b)) / (exp(T/tau) - 1);
        d = 0.5 * tau * exp(0.5*(sigma/tau)^2+mu/tau);
        
        P = 0.5 * erf(a*(t-mu));
        Q = erf(b-t*a);
        R = exp(-t/tau);
        
        h = tau * P + d .* R .* (Q + c);        
    end
        
    function [analytical_decay, irf] = generate_decay(I, tau, mu, sigma, offset)
        irf = normpdf(t_irf,mu,sigma);
        analytical_decay = I * (H(t+dt, tau, mu, sigma) - H(t, tau, mu, sigma)) + offset;
    end


end
