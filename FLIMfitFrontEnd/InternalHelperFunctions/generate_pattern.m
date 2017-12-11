function pattern = generate_pattern(td, d, tirf, irf, T, fit_ax, res_ax)
        
    dt = td(2)-td(1);
    
    dtirf = tirf(2)-tirf(1);
    
    extra = ((tirf(end) + dtirf):dtirf:td(end))';  
    tirf = [tirf; extra];
    irf = [irf; zeros(size(extra))];
    
    sel = arrayfun(@(x) any(td==x), tirf);

    
    opts = optimset('MaxFunEvals', 5000, 'MaxIter', 5000);

    count = 0;
    
    [x,chi2_final] = fminsearch(@fit,[100 3000 5000 0.33 0.33 0.33], opts);
    
    count = 0;
    [~,I] =fit(x);
        
    tau = x(1:3);
    beta = x(4:6);
    beta = beta * I;
    %offset = x(7) / norm;
    
    pattern = [tau(1) beta(1) tau(2) beta(2) tau(3) beta(3) 0]
            
    function [chi2,I] = fit(x)
        x = min(x,1e4);
        tau1 = x(1);
        tau2 = x(2);
        tau3 = x(3);
        beta1 = x(4);
        beta2 = x(5);
        beta3 = x(6);
        offset = 0; %x(7);
        
        dc1 = generate_decay(1, tau1);
        dc2 = generate_decay(1, tau2);
        dc3 = generate_decay(1, tau3);
        
        dc = beta1 * dc1 + beta2 * dc2 + beta3 * dc3 + offset;
        
        I = dc \ d;
        dc = I * dc;
        
        n_free = length(d) - length(x);
        chi2 = sum((d-dc).^2./d)/n_free;
        
        if mod(count,200) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            plot(fit_ax,td,d,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,td,dc,'-b');
            %plot(fit_ax,irft,irfc/max(irfc)*max(d),'r');
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

    function [dc] = generate_decay(I, tau)
        dc = I * conv_irf(tirf,irf,tau);
        dc = dc(sel);        
    end

    function D = conv_irf(tg,g,tau)
       
        % See thesis page: 69-70
        
        rhoi = exp(tg/tau);
        G = g.*rhoi;
        G = cumsum(G);
        G = circshift(G,1);
        G(1) = 0;
        rho = exp(dtirf / tau);
        
        A = tau.^2/dtirf* (1-rho)^2/rho;
        B = tau.^2/dtirf * (dtirf / tau - 1 + 1/rho);
        
        C = A * G + B * g .* rhoi;
        
        f = 1 / (exp(T/tau)-1);
        
        D = (C + f * C(end))./ rhoi * dtirf;
        
    end

end
