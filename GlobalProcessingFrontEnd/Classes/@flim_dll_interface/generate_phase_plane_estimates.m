function tau_est = generate_phase_plane_estimates(obj,d,decay,n_tau,tau_min,tau_max)
    
    decay = squeeze(decay);
    sz = size(decay);
    n = prod(sz(2:end));
    
    decay = reshape(decay,[sz(1) n]);

    tau_est = zeros([n_tau, n]);

    for i=1:n

        tau = phase_plane_estimation(d.t,d.irf,decay(:,i),n_tau);
        tau = sort(tau,'descend');

                        
        if tau(2) < 200
            tau(2) = 0.6 * tau(1);
        end

        if tau(1) - tau(2) < 100
            tau(1) = tau(1) + 100;
        end
        
        %tau_est = real(tau_est);
        
        %{
        % Enforce tau limits
        for j=1:n_tau
            if tau(j) > 0.9 * tau_max(j)
                tau(j) = 0.9 * tau_max(j);
            end
        end
        
        for j=(n_tau-1):-1:1
            if tau(j) < tau_min(j)
                if tau(j+1) < tau_min / 0.6
                    tau(j) = tau(j+1);
                else
                    tau(j) = 0.6 * tau(j+1);
                end
            end
        end
        %}
        
       tau_est(:,i) = real(tau);
    end
    
    tau_est = reshape(tau_est,[n_tau sz(2:end)]);
    
            figure();
        subplot(2,2,1);
        imagesc(squeeze(tau_est(1,:,:)));
        colorbar()
        caxis([0 4000])
        subplot(2,2,2);
        imagesc(squeeze(tau_est(2,:,:)));
        colorbar();
        caxis([0 4000])

end