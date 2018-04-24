function results = interactiveQ(t,data,irf)

addpath('Simulations');


model.donor = make_fluorphore(3950, 1, 1, 1, [1 2.58]);
model.acceptor = make_fluorphore(3120, 1, 1, 0.1, [1 0]);
model.system.t0 = 200;
model.system.kt0 = 1/10000;

system.irf.width = [irf.sigma];
system.irf.centre = [irf.mu];
system.trep = 12500;
system.dt = 500;
system.nbin = system.trep / system.dt;
system.nchan = 2;

vars(1) = struct('name','kt0','group','system','constrain_positive',true);
vars(2) = struct('name','t0','group','system','constrain_positive',false);

model = optimise_model(model,vars,@(m) evaluate_model(m,[1]));

vars(1) = struct('name','Q','group','acceptor','constrain_positive',true);
vars(2) = struct('name','sigma','group','acceptor','constrain_positive',true);

[model,fval] = optimise_model(model,vars,@(m) evaluate_model(m,[1 2]));

E = 1 - 1/(1/model.donor.tau + model.system.kt0) / model.donor.tau;

disp(['E = ' num2str(E)]);
disp(['t0 = ' num2str(model.system.t0)]);
disp(['Q = ' num2str(model.acceptor.Q)]);
disp(['sigma = ' num2str(model.acceptor.sigma)]);

results.E = E;
results.t0 = model.system.t0;
results.Q = model.acceptor.Q;
results.sigma = model.acceptor.sigma;

results.fval = fval;

[r,decay] = evaluate_model(model,[1 2]);
plot(t,data,'o');
hold on;
set(gca,'ColorOrderIndex',1)
plot(t,decay);
hold off
drawnow


    function [r,decay] = evaluate_model(m,ch)

        mode = 'static';

        system1 = system;
        system1.irf.centre = system1.irf.centre + m.system.t0;
        
        decay = model_fret(m.donor, m.acceptor, m.system.kt0, mode, system1);
        decay = decay(2:end,:); % we cut off t=0
        decay = decay(:,ch);
        
        sel_data = data(:,ch);
        
        I = decay(:) \ sel_data(:);
        decay = decay * I;

        r = mean((decay(:) - sel_data(:)).^2 ./ sel_data(:));
        
    end

end