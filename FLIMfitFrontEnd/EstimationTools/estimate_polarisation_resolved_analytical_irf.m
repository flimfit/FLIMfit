function [analytical_params,chi2_final] = estimate_polarisation_resolved_analytical_irf(t, decay, T, fit_ax, res_ax)
        
    dt = t(2)-t(1);
    dvalid = decay > 0;
    
    t_irf = min(t):25:max(t);
    
    opts = optimset('MaxFunEvals', 10000);

    tau0 = 3500;
    theta0 = 200;
    sigma0 = [250 250];
    g0 = 0.9;
    a0 = 0.95;
    [~,idx] = max(decay);
    t00 = t(idx)' - sigma0;

    count = 0;
    [x,chi2_final] = fminsearch(@fit, [tau0, theta0, g0, sigma0, t00, a0, 0.95], opts);
    
    count = 0;
    fit(x);
    
    analytical_params(1).sigma = x(4);
    analytical_params(1).mu = x(6);
    analytical_params(1).offset = 0;

    analytical_params(2).sigma = x(5);
    analytical_params(2).mu = x(7);
    analytical_params(2).offset = 0;
    
    % Display Results
    disp(['t0: ' num2str(x(6:7)) ' ps']);
    disp(['sigma: ' num2str(x(4:5)) ' ps']);
    disp(['g: ' num2str(x(3)) ' ps']);
    disp(['a: ' num2str(x(8))]);
    disp(['tau: ' num2str(x(1)) ' ps']);
    disp(['theta: ' num2str(x(2)) ' ps']);
    disp(['NA: ' num2str(x(9))]);
    
    function chi2 = fit(x)
        tau = x(1);
        theta = x(2);
        g = x(3);
        sigma = x(4:5);
        t0 = x(6:7);
        a = pi/2; x(8);
        %nu = [-1+a 2*(1-a)]; fitted depolarisation
        nu = 3 / 2 * [cos(a)^2 cos(a + pi/2)^2] - 1 / 2; % angle to excitation 
        
        for i=1:length(t0)
            irf(:,i) = normpdf(t_irf, t0(i), sigma(i));
            F = generate_decay_analytical_irf(t, dt, T, tau, t0(i), sigma(i));
            Fr = generate_decay_analytical_irf(t, dt, T, 1/(1/tau+1/theta), t0(i), sigma(i));
            I(:,i) = 1/3*(F+nu(i)*Fr);
        end
        I(:,1) = I(:,1) * g;
        
        NA = x(9); % NA of objective
        n = 1.333; % refractive index of water

        omega = asin(NA / n);

        %Compute K factors based on Axelrod, 1979 [doi:10.1016/S0006-3495(79)85271-6]
        Ka = 1/3 * (2 - 3*cos(omega) + cos(omega)^3);
        Kb = 1/4 * (5 - 3*cos(omega) - cos(omega)^2 - cos(omega)^3);
        Kc = 1/12 * (1 - 3*cos(omega) + 3*cos(omega)^2 - cos(omega)^3);
        
        IA(:,1) = (Ka+Kb) * I(:,1) + Kc * I(:,2);
        IA(:,2) = (Ka+Kc) * I(:,1) + Kb * I(:,2);
        
        I = IA;
        
        I0 = I(:) \ decay(:);
        analytical_decay = I0 * I;
        
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
