
set(groot,'defaultAxesColorOrder',[0 0 1;
                                   0 1 0;
                                   1 0 0]);

rho.donor = make_fluorphore(2630, 1, 0.6, 1, [1.4 12 1]);
rho.acceptor = make_fluorphore(1640, 1, 0.25, 0.5, [1 2.35 191]);

rac.donor = make_fluorphore([3350 1330], [0.566 0.434], 0.4, 1, [5 7.6 1]);
rac.acceptor = make_fluorphore(2500, 1, 0.57, 0.09, [1 954 198]);

system = make_system();
    
n_photon =  5e6;

kt = [1e-6 2.5e-4 6e-4];

idx = 1;
for mode = {'static'}
    for c = [rho]
        for i=1:length(kt)

            decay = simulate(c.donor, c.acceptor, kt(i), mode, system, n_photon);
            decaym = n_photon * model(c.donor, c.acceptor, kt(i), mode, system);

            %decay = decay / max(decay(:));
            %decaym = decaym / max(decaym(:));
            
            subplot(length(kt),1,idx)
            plot(decay,'-');
            ylim([0 5e4])
            title(num2str(mean_arrival(decay,system,2)));

            subplot(length(kt),1,idx);
            hold on;
            plot(decaym,'--');
            ylim([0 5e4])
            title(num2str(mean_arrival(decaym,system,2)));
            hold off;
            idx = idx + 1;
            
            %ylim([1e3 5e5])
            %title(num2str(mean_arrival(decaym,system,2)));
            %[mean_arrival(decay,system,1) mean_arrival(decay,system,2) mean_arrival(decay,system,3)]
        end
    end
end