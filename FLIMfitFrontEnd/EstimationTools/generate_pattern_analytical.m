function pattern = generate_pattern_analytical(td, d, mu, sigma, T, fit_ax, res_ax)
            
    dt = td(2)-td(1);
    dvalid = d > 0;
    
    
    opts = optimset('MaxIter', 10000);

    count = 0;
    
    tau = [100 1000 8000];
    beta = [0.33 0.33 0.33];
    offset = 0;
    I = 1;
        
    fminsearch(@fit,[log(tau-50) beta(1:(end-1))], opts);
       
    beta = beta * I;
    offset = offset * I;
    
    pattern = [tau(1) beta(1) tau(2) beta(2) tau(3) beta(3) 0];
    tau
    beta
    offset
            
    function chi2 = fit(x)
        x = min(x,1e4);
        tau = exp(x(1:3)) + 50; % Constrain tau above 50ps
        beta = x(4:5);
        beta(3) = 1 - sum(beta);
        %offset = x(6);

        dc = offset;
        for i=1:length(tau)
            dc = dc + beta(i) * generate_decay_analytical_irf(td, dt, T, tau(i), mu, sigma);
        end
        
        I = dc \ d;
        dc = I * dc;
        
        n_free = length(d) - length(x);
        A = d(dvalid) .* log(dc(dvalid)./d(dvalid));
        chi2 = -2 * ( sum(d-dc) + sum(A)) / n_free;
        
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

end
