function [irf_final,t_final,chi2_final] = estimate_irf(td, d, T, fit_ax, res_ax)
        
    dt = td(2)-td(1);
    
    if (dt > 250)
        dt = 25;
    end
        
    t = -max(td):1:max(td);
    dc = [];
    
    opts = optimset('Display', 'iter', 'MaxFunEvals', 10000);

    tau0 = 4000;
    sigma0 = 100;
    lambda0 = 1/100;

    [~,idx] = max(d);
    t0 = td(idx) - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, t0, sigma0, lambda0 0], opts);
    
    count = 0;
    fit(x);
    
    % Display Results
    disp(['t0: ' num2str(x(2)) ' ps']);
    disp(['sigma: ' num2str(x(3)) ' ps']);
    disp(['tau: ' num2str(x(1)) ' ps']);
    
    irf_final = irfc;
    t_final = irft;    
        
    function chi2 = fit(x)
        tau = x(1);
        t0 = x(2);
        sigma = x(3);
        lambda = x(4);
        offset = x(5);
        I = 1;
        
        [dc,irfc,irft] = generate_decay(I, tau, t0, sigma, lambda, offset);
        
        I = dc \ d;
        dc = I * dc;
        
        n_free = length(d) - length(x);
        chi2 = sum((d-dc).^2./d)/n_free;
        
        if mod(count,20) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            plot(fit_ax,td,d,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,td,dc,'-b');
            plot(fit_ax,irft,irfc/max(irfc)*max(d),'r');
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

    function [dc,binned_irf,binned_t] = generate_decay(I, tau, mu, sigma, lambda, offset)
        irf = exp(lambda/2.*(2*mu+lambda*sigma^2-2*t)).*erfc((mu+lambda*sigma^2-t)/(sqrt(2)*sigma));
        
        [binned_irf, binned_t] = bin_decay(irf);
        dc = I * conv_irf(binned_t,binned_irf,tau);
        dc = dc + offset;
        %dc = dc((end-length(td)+1):end) + offset;
        
        sel = arrayfun(@(x) any(td==x), binned_t);
        dc = dc(sel);
        
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
