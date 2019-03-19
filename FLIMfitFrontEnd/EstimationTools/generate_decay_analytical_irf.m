function [analytical_decay] = generate_decay_analytical_irf(t, dt, T, tau, mu, sigma)

    % Generate a exponential decay with lifetime tau convolved with a
    % gaussian IRF with centre mu and width sigma sampled at t with bin
    % width dt and repetition period T.    
    % Accounts for analyical convolution across bin width
    % See Mathematica document for more details   
    
    analytical_decay = (H(t+dt, tau, mu, sigma) - H(t, tau, mu, sigma)) / dt;

    function h = H(t, tau, mu, sigma)
        a = 1 / (sqrt(2) * sigma);
        b = (sigma^2 / tau + mu) * a;
        c = (erf(b - T * a) - exp(T/tau) * erf(b)) / (exp(T/tau) - 1);
        d = 0.5 * tau;
        
        r0 = 0.5*(sigma/tau)^2+mu/tau;

        if ~isfinite(c); c = -1; end
        %if (d == inf); d = 0; end
        
        P = 0.5 * erf(a*(t-mu));
        Q = erf(b-t*a);
        R = exp(r0-t/tau);
        R(R==inf) = realmax;
        
        h = tau * P + d .* (R .* (Q + c));     
    end

end
    