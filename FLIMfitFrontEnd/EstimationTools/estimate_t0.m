function [mu,sigma] = estimate_t0(td, d, mu0, sigma0, T, fit_ax, res_ax)
            
    d = double(d);
    dt = td(2)-td(1);
    dvalid = d > 0;
    
    
    scale = max(d);
    ds = d / scale;
    
    opts = optimset('MaxIter', 1e3, 'MaxFunEval', 1e3, 'TolX', 1e-6, 'TolFun', 1e-6);

    count = 0;
    
    tau = logspace(log10(100),log10(10000),16);
    
    beta = [];
        
    has_ax = nargin == 7;
    
    %[~,idx] = max(d);
    %mu0 = td(idx) - sigma;
    
    xf = fminsearch(@fit,[mu0 sigma0], opts);
    fit(xf,true);
                
    %disp([mu-mu0,sigma/1000]);
    
    function chi2 = fit(x, forcedraw)
        mu = x(1);
        sigma = x(2);
        
        dc = [];
        for i=1:length(tau)
            dc(:,i) = generate_decay_analytical_irf(td, dt, T, tau(i), mu, sigma);
        end
        % dc(:,end+1) = 1;
            
        %beta = (dc \ ds) * scale;
        beta = lsqnonneg(dc,ds) * scale;
        dc = dc * beta;
        
        n_free = length(d) - length(x);
        A = d(dvalid) .* log(dc(dvalid)./d(dvalid));
        chi2 = -2 * ( sum(d-dc) + sum(A)) / n_free;
        
        if nargin < 2
            forcedraw = false;
        end
        
        
        if has_ax && (mod(count,200) == -1 || forcedraw)
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end
            
            irft = 0:10:10000;
            irfc = normpdf(irft,mu,sigma);
            
            semilogy(fit_ax,td,d,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            semilogy(fit_ax,td,dc,'-b');
            semilogy(fit_ax,irft,irfc/max(irfc)*max(d),'r');
            xlim(fit_ax,[min(td),max(td)])
            ylim(fit_ax,[0.8*min(d) 1.2*max(d)])
            hold(fit_ax,'off');
            set(fit_ax,'Box','off','TickDir','out')
            xlabel(fit_ax,'Time (ps)');
            ylabel(fit_ax,'Intensity');
            text(fit_ax,max(td),1.2*max(d),label,'HorizontalAlignment','right','FontSize',12,'BackgroundColor',label_color);
            
            %plot(res_ax,tau,beta,'x-')
            plot(res_ax,td,(d-dc)./sqrt(d)/n_free,'b');
            set(res_ax,'Box','off','TickDir','out')
            xlim(res_ax,[min(td),max(td)])
            drawnow
        end
        count = count + 1;
    end

end
