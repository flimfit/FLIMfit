function tau_est = generate_phase_plane_estimates(obj,d,decay,n_tau,tau_min,tau_max)

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren

    
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