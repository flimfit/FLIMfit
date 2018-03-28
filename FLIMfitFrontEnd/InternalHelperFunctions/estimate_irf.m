function [irf,t_irf,chi2_final] = estimate_irf(td, d, T, fit_ax, res_ax)
        
    dt = td(2)-td(1);
    
    if (dt > 250)
        dt = 25;
    end
       
    t_end = max(td);
    t_start = -round(0.2 * max(td) / dt) * dt;
    t = t_start:t_end;
    
    t_irf = (t_start:dt:t_end)';
    t_sel = arrayfun(@(x) any(td==x), t_irf);
    
    dvalid = d > 0;
    
    opts = optimset('MaxFunEvals', 100000);

    tau0 = 4000;
    tau2 = 1000;
    beta = 1;
    sigma0 = 300;
    lambda0 = 1/50;

    [~,idx] = max(d);
    t0 = td(idx) - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, tau2, beta, t0, sigma0, lambda0, 0], opts);
    
    count = 0;
    fit(x);
    
    % Display Results
    disp(['t0: ' num2str(x(2)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);
    disp(['tau: ' num2str(x(1)) ' ps']);
    disp(['offset: ' num2str(x(5))]);
            
    function chi2 = fit(x)
        tau = x(1);
        tau2 = x(2);
        beta = x(3);
        t0 = x(4);
        sigma = x(5);
        lambda = x(6);
        offset = x(7);
        
        irf = generate_irf(t0, sigma, lambda);
        dc = generate_decay_measured_irf(t_irf,irf,T,tau);
        dc2 = generate_decay_measured_irf(t_irf,irf,T,tau2);

        dc = beta * dc + (1-beta) * dc2 + offset; 
        dc = dc(t_sel);

        I = dc \ d;
        dc = I * dc;
        
        n_free = length(d) - length(x);

        % Use maximum likelihood estimator
        A = d(dvalid) .* log(dc(dvalid)./d(dvalid));
        chi2 = -2 * ( sum(d-dc) + sum(A)) / n_free;
        
        if mod(count,100) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            plot(fit_ax,td,d,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,td,dc,'-b');
            plot(fit_ax,t_irf,irf/max(irf)*max(d),'r');
            xlim(fit_ax,[min(td),max(td)])
            ylim(fit_ax,[0 1.2*max(d)])
            hold(fit_ax,'off');
            set(fit_ax,'Box','off','TickDir','out')
            xlabel(fit_ax,'Time (ps)');
            ylabel(fit_ax,'Intensity');
            text(fit_ax,max(td),1.2*max(d),label,'HorizontalAlignment','right','FontSize',12,'BackgroundColor',label_color);
            
            plot(res_ax,td,(d-dc)./sqrt(d)/n_free,'b');
            set(res_ax,'Box','off','TickDir','out')
            xlim(res_ax,[min(td),max(td)])
            drawnow
        end
        count = count + 1;
    end

    function [irf] = generate_irf(mu, sigma, lambda)
        
        % Generate IRF at 1ps sampling
        irf = exp(lambda/2.*(2*mu+lambda*sigma^2-2*t)).*erfc((mu+lambda*sigma^2-t)/(sqrt(2)*sigma));
%        irf = exp(-((t-mu)/sigma).^2)/(sqrt(2)*sigma);                       
        irf(~isfinite(irf)) = 0;
        
        % Bin the IRF
        tg = ceil(t / dt);
        tgm = min(tg);
        irf = accumarray(tg'-tgm+1,irf');
    end
end
