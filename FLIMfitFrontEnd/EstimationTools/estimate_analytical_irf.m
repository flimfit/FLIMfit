function [analytical_params,chi2_final] = estimate_analytical_irf(t, decay, T, fit_ax, res_ax)
        
    dt = t(2)-t(1);
    dvalid = decay > 0;
    
    t_irf = min(t):25:max(t);
    
    opts = optimset('MaxFunEvals', 10000);

    tau0 = 4000;
    theta0 = 400;
    r00 = 0.55;
    sigma0 = 300;

    [~,idx] = max(decay);
    t00 = t(idx) - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, theta0, sigma0, t00' ], opts);
    
    count = 0;
    fit(x);
    
    for j=1:size(decay,2)
        analytical_params(j).mu = x(3+j);
        analytical_params(j).sigma = x(3);
        analytical_params(j).offset = 0;
    end
    
    % Display Results
    disp(['t0: ' num2str(x(4:end)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);
    disp(['tau: ' num2str(x(1)) ' ps']);
    disp(['theta: ' num2str(x(2)) ' ps']);
    %disp(['r0: ' num2str(x(4))]);
    %disp(['offset: ' num2str(x(6))]);
    
    function chi2 = fit(x)
        tau = x(1);
        theta = x(2);
        sigma = x(3);
        t0 = x(4:end);
        r0 = 0;
        offset = 0;
        
        for i=1:length(t0)
            irf = normpdf(t_irf, t0(i), sigma);
            F = generate_decay_analytical_irf(t, dt, T, tau, t0(i), sigma);
            Fr = generate_decay_analytical_irf(t, dt, T, 1/(1/tau+1/theta), t0(i), sigma);

            analytical_decay(:,i) = 2 * F + 0.5 * r0 * Fr + offset;
            I = analytical_decay(:,i) \ decay(:,i);
            analytical_decay(:,i) = I * analytical_decay(:,i);
            
            irf_display(:,i) = irf;
        end
        
        
        n_free = numel(decay) - numel(x);

        % Use maximum likelihood estimator
        A = decay(dvalid) .* log(analytical_decay(dvalid)./decay(dvalid));
        chi2 = -2 * ( sum(decay(:)-analytical_decay(:)) + sum(A(:))) / n_free;
        
        if mod(count,500) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            max_decay = max(decay(:));
            plot(fit_ax,t,decay,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,t,analytical_decay,'-b');
            plot(fit_ax,t_irf,irf_display/max(irf_display(:))*max_decay,'r');
            xlim(fit_ax,[min(t),max(t)])
            ylim(fit_ax,[0 1.2*max_decay])
            hold(fit_ax,'off');
            set(fit_ax,'Box','off','TickDir','out')
            xlabel(fit_ax,'Time (ps)');
            ylabel(fit_ax,'Intensity');
            text(fit_ax,max(t),1.2*max_decay,label,'HorizontalAlignment','right','FontSize',12,'BackgroundColor',label_color);
            
            plot(res_ax,t,(decay-analytical_decay)./sqrt(decay)/n_free,'b');
            set(res_ax,'Box','off','TickDir','out')
            xlim(res_ax,[min(t),max(t)])
            drawnow
        end
        count = count + 1;
    end

end
