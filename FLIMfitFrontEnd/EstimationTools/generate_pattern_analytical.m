function pattern = generate_pattern_analytical(td, d, mu, sigma, T, fit_ax, res_ax)
            
    dt = td(2)-td(1);
    dvalid = d > 0;
        
    tau = logspace(log10(100),log10(30000),32)';
    
    dc = [];
    for i=1:length(tau)
        dc(:,i) = generate_decay_analytical_irf(td, dt, T, tau(i), mu, sigma);
    end

    beta = lsqnonneg(dc,d);
    dc = dc * beta;

    n_free = length(d) - sum(beta>0);
    A = d(dvalid) .* log(dc(dvalid)./d(dvalid));
    chi2 = -2 * ( sum(d-dc) + sum(A)) / n_free;

    pattern = [tau beta]';
    pattern = [pattern(:)' 0];

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
