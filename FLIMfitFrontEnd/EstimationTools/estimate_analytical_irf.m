function [analytical_params,chi2_final] = estimate_analytical_irf(t, decay, T, fit_ax, res_ax)
        
    dt = t(2)-t(1);
    dvalid = decay > 0;
    
    t_irf = min(t):25:max(t);
    
    opts = optimset('MaxFunEvals', 10000);

    tau0 = 4000;
    theta0 = 400;
    a0 = 0.55;
    sigma0 = 300;

    [~,idx] = max(decay);
    t0 = t(idx) - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, theta0, t0, sigma0, 1e-5 ], opts);
    
    count = 0;
    fit(x);
    
    analytical_params.sigma = x(4);
    analytical_params.mu = x(3);
    analytical_params.offset = 0;
    
    % Display Results
    disp(['t0: ' num2str(x(3)) ' ps']);
    disp(['sigma: ' num2str(x(4)) ' ps']);
    disp(['tau: ' num2str(x(1)) ' ps']);
    disp(['theta: ' num2str(x(2)) ' ps']);
    disp(['offset: ' num2str(x(5))]);
    
    function chi2 = fit(x)
        tau = x(1);
        theta = x(2);
        t0 = x(3);
        sigma = x(4);
        offset = x(5);
        
        irf = normpdf(t_irf, t0, sigma);
        F = generate_decay_analytical_irf(t, dt, T, tau, t0, sigma);
        Fr = generate_decay_analytical_irf(t, dt, T, 1/(1/tau+1/theta), t0, sigma);

        analytical_decay = 2 * F + 0.5 * Fr + offset;
        
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

end
