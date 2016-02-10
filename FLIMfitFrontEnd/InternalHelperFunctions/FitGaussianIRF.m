function irf_final = FitGaussianIRF(td, d, ax)

dt = td(2)-td(1);
t = -max(td):1:max(td);
T = 12500;
decay_fcn = @(tau,t) ((t>0).*exp(-t/tau) + ((t+T)>0).*exp(-(t+T)/tau) + ((t+2*T)>0).*exp(-(t+2*T)/tau) + ((t+3*T)>0).*exp(-(t+3*T)/tau) + ((t+4*T)>0).*exp(-(t+4*T)/tau));
sel = ismember(int32(t), int32(td));
sum(sel)
irf = [];
dc = [];

opts = optimset('Display', 'iter');

[I0,idx] = max(d);
t0 = td(idx);

tau0 = 4000;
sigma0 = 70;

count = 0;

offset0 = 1e-10;
x = fminsearch(@fit, [tau0, t0, sigma0, I0], opts);


irf_final = irfc(sel);
irf_final = irf_final / sum(irf_final);

plot(ax, td,[d dc]);
hold on;
plot(ax, td,irf_final / max(irf_final));
hold off;


    function r = fit(x)
        tau = x(1);
        t0 = x(2);
        sigma = x(3);
        I = x(4);
        [dc,irfc] = generate_decay(I, tau, t0, sigma, 0);
        
        if mod(count,20) == 0
            plot(td,d,'ob','MarkerSize',3);
            hold on;
            plot(td,dc,'-b');
            plot(t,irfc/max(irfc)*max(d),'r');
            xlim([min(td),max(td)])
            drawnow
            hold off;
        end
        count = count + 1;
        r = sum((d-dc).^2);
    end

    function [dc,irf] = generate_decay(I, tau, t0, sigma, offset)
        irf = normpdf(t,t0,sigma) + offset;

        dc = I * decay_fcn(tau, t);
        dc = conv(dc,irf,'same');
        dc = dc(1:length(t));
        dc = dc(sel)';
    end

end
