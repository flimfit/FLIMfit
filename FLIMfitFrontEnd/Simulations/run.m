
set(groot,'defaultAxesColorOrder',[0 0 1;
                                   0 1 0;
                                   1 0 0]);

rho.donor = make_fluorphore(2630, 1, 0.6, 1, [1.4 12 1]);
rho.acceptor = make_fluorphore(1640, 1, 0.25, 0.10, [1 2.35 191]);

rac.donor = make_fluorphore([3350 1330], [0.566 0.434], 0.4, 1, [5 7.6 1]);
rac.acceptor = make_fluorphore(2500, 1, 0.57, 0.0, [1 954 198]);

rac.donor = make_fluorphore([3350 1330], [0.566 0.434], 0.4, 1, [1 0 0]);
rac.acceptor = make_fluorphore(2500, 1, 1, 0.1, [0 1 1]);


system = make_system();
    
t = (0:(system.nbin-1))' * system.dt;


cons = rac;
effectiveQ = (cons.acceptor.Q / cons.acceptor.tau) / (cons.donor.Q / cons.donor.tau)


gaussian_params = struct('mu',system.irf.centre,'sigma',system.irf.width,'offset',0);
gaussian_params = repmat(gaussian_params,[1 system.nchan]);

json = jsonencode(gaussian_params);
f = fopen('irf.json','w');
fwrite(f,json);
fclose(f);

n_photon =  5e6;

tauT = [1e6 8000 4000];

kt = 1./tauT;

%kt = [1e-6 2.5e-4 6e-4];

idx = 1;
for mode = {'static'}
    for c = [cons]
        for i=1:length(kt)

            decay = simulate_fret(c.donor, c.acceptor, kt(i), mode, system, n_photon);
            decaym = n_photon * model_fret(c.donor, c.acceptor, kt(i), mode, system);

            %decay = decay / max(decay(:));
            %decaym = decaym / max(decaym(:));
            
            subplot(length(kt),3,idx)
            idx = idx + 1;
            plot(t,decay,'-');
            ylim([0 5e4])
            title(num2str(mean_arrival(decay,system,2)));

            subplot(length(kt),3,idx)
            idx = idx + 1;
            plot(t,decaym,'-');
            ylim([0 5e4])
            title(num2str(mean_arrival(decaym,system,2)));

            subplot(length(kt),3,idx)
            idx = idx + 1;
            plot(t,(decaym-decay)./sqrt(decaym),'-');
            ylim([-5 5])
            %ylim([0 5e4])
            title(num2str(mean_arrival(decaym,system,2)));
            
            %ylim([1e3 5e5])
            %title(num2str(mean_arrival(decaym,system,2)));
            %[mean_arrival(decay,system,1) mean_arrival(decay,system,2) mean_arrival(decay,system,3)]
            
            tbl = array2table([t decay],'VariableNames',{'t', 'ch1', 'ch2', 'ch3'});
            writetable(tbl,['Simulated_' num2str(i) '.csv']);
            
        end
    end
end