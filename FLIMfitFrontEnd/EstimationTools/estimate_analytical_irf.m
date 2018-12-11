function [analytical_params,chi2_final] = estimate_analytical_irf(t, decay, polarisation, T, fit_ax, res_ax)
        
    polarisation_resolved = any(polarisation ~= Polarisation.Unpolarised);
    n_chan = size(decay,2);
    
    for c=1:n_chan
        switch polarisation(c)
            case Polarisation.Parallel
                pol_angle(c) = 0;
            case Polarisation.Perpendicular
                pol_angle(c) = pi/2;
            otherwise
                pol_angle(c) = nan;
        end
    end
    
    dt = t(2)-t(1);
    dvalid = decay > 0;
    
    t_irf = min(t):25:max(t);
    
    opts = optimset('MaxFunEvals', 10000);

    params.tau = 3500;
    params.theta = 200;
    params.sigma = 600;
    params.g = 1.0;
    params.offset = 1e-5 * ones([1 n_chan]);
    
    [~,idx] = max(decay);
    t0 = t(idx)' - params.sigma;

    params.t0 = t0;
    
    fitted_names = {'tau','sigma','t0','offset'};
    if polarisation_resolved
        fitted_names = [fitted_names, {'theta','g'}];
    end
    
    obj = FittingObject(params, fitted_names);
    
    count = 0;
    [x,chi2_final] = fminsearch(@fit, obj.get_initial(), opts);
    params = obj.get(x);
    
    count = 0;
    fit(x);
        
    for c=1:n_chan
        analytical_params(c).sigma = params.sigma;
        analytical_params(c).mu = params.t0(c);
        analytical_params(c).offset = 0;
    end
    
    % Display Results
    disp(['t0: ' num2str(params.t0) ' ps']);
    disp(['sigma: ' num2str(params.sigma) ' ps']);
    disp(['tau: ' num2str(params.tau) ' ps']);

    if polarisation_resolved
        disp(['g: ' num2str(params.g)]);
        disp(['theta: ' num2str(params.theta) ' ps']);
    end
    
    function chi2 = fit(x)
        p = obj.get(x);
        
        nu = 3 / 2 * cos(pol_angle).^2 - 1 / 2; % angle to excitation 
        
        for i=1:n_chan
            irf(:,i) = normpdf(t_irf, p.t0(i), p.sigma);
            F = generate_decay_analytical_irf(t, dt, T, p.tau, p.t0(i), p.sigma);
            
            if isfinite(nu(i))
                Fr = generate_decay_analytical_irf(t, dt, T, 1/(1/p.tau+1/p.theta), p.t0(i), p.sigma);
                I(:,i) = 1/3*(F+nu(i)*Fr);
            else
                I(:,i) = F;
            end 
            
            I(:,i) = I(:,i) + p.offset(i);
        end
        I(:,2) = I(:,2) * p.g;
      
        if polarisation_resolved
            I0 = I(:) \ decay(:);
            analytical_decay = I0 * I;
        else
            for i=1:n_chan
                I0 = I(:,i) \ decay(:,i);
                analytical_decay(:,i) = I0 * I(:,i);
            end
        end
        
        %{
        n = 1.333; % refractive index of water
        omega = asin(NA / n);

        %Compute K factors based on Axelrod, 1979 [doi:10.1016/S0006-3495(79)85271-6]
        Ka = 1/3 * (2 - 3*cos(omega) + cos(omega)^3);
        Kb = 1/4 * (5 - 3*cos(omega) - cos(omega)^2 - cos(omega)^3);
        Kc = 1/12 * (1 - 3*cos(omega) + 3*cos(omega)^2 - cos(omega)^3);
        
        IA(:,1) = (Ka+Kb) * I(:,1) + Kc * I(:,2);
        IA(:,2) = (Ka+Kc) * I(:,1) + Kb * I(:,2);
        
        I = IA;
        %}
        
        
        n_free = numel(decay) - length(x);

        % Use maximum likelihood estimator
        A = decay(dvalid) .* log(analytical_decay(dvalid)./decay(dvalid));
        chi2 = -2 * ( sum(decay(:)-analytical_decay(:)) + sum(A(:))) / n_free;
        
        if mod(count,100) == 0
            label = ['\chi^2 = ' num2str(chi2,4)];
            if chi2 < 1.3
                label_color = 'g';
            else
                label_color = 'r';
            end 
            
            maxy = 1.2*max(decay(:));
            plot(fit_ax,t,decay,'ob','MarkerSize',3);
            hold(fit_ax,'on');
            plot(fit_ax,t,analytical_decay,'-b');
            plot(fit_ax,t_irf,irf/max(irf(:))*maxy,'r');
            xlim(fit_ax,[min(t),max(t)])
            ylim(fit_ax,[0 maxy])
            hold(fit_ax,'off');
            set(fit_ax,'Box','off','TickDir','out')
            xlabel(fit_ax,'Time (ps)');
            ylabel(fit_ax,'Intensity');
            text(fit_ax,max(t),maxy,label,'HorizontalAlignment','right','FontSize',12,'BackgroundColor',label_color);
            
            plot(res_ax,t,(decay-analytical_decay)./sqrt(decay)/n_free,'b');
            set(res_ax,'Box','off','TickDir','out')
            xlim(res_ax,[min(t),max(t)])
            drawnow
        end
        count = count + 1;
    end

end
