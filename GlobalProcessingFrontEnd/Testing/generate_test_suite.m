%%

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

addpath('../FLIMMatlabUtilities');

[t_irf_wf,irf_wf] = open_flim_files('','sim/irf7.irf');
irf_wf = irf_wf ./ norm(irf_wf(:));

t_irf_tc = 0:200:4000;
irf_tc = normpdf(t_irf_tc,2000,150);
irf_tc = irf_tc ./ norm(irf_tc(:));
%{  
[t_irf_tc,irf_tc] = open_flim_files('','sim/daspi_irf_tcspc.irf');
irf_tc = irf_tc ./ norm(irf_tc(:));
t_irf_tc = t_irf_tc * 1000;
%}
t_wf = [0 4500 5500 6500 8000 10000 12000];   
t_tc = (0:63) * 12.5e3/64;

avg = [200 500 2000 5000 10000];


%%

%%-----------------------------------------------------------
% FRET EXPERIMENT FITTING
%-----------------------------------------------------------

%t_wf = [0 4500 5500 6500 8000 10000 12000];  

t_wf = [0 4500 6000 7500 9000 10500 12000];

%t_wf = [1469.40568947416 1896.28894805126 7753.43441892728 9265.97941228939 9268.9924223118 9965.95443765402];
%t_wf = [1321.52026897928 1579.97399793508 7197.72982055721 7519.11023876321 8097.41831548983 9325.33194482152 10204.4854314588];

avg = [500 1000 2000 5000 10000];

crop_data = false;
t = t_wf;
t_irf = t_irf_wf; %t_irf_wf;
irf = irf_wf; %irf_wf;

fit_mode = 0;
global_mode = 'global';

tau1 = 3750;
dt = [250 500 750 1000 1250];
tau2 = tau1-dt;

f = ['Z:\Users\scw09\DataTransfer\SimFRET-' global_mode '-' num2str(fit_mode)];


est_tau1 = zeros(length(avg),length(tau2));
est_tau2 = zeros(length(avg),length(tau2));
est_beta_rms_err = zeros(length(avg),length(tau2));
est_beta_bias = zeros(length(avg),length(tau2));
est_beta_corr = zeros(length(avg),length(tau2));
est_beta_map = cell(length(avg),length(tau2));
est_tau_single_map = cell(length(avg),length(tau2));

for i=1:length(avg)
    for j=1:length(tau2)
        
        te1 = [];
        te2 = [];
            
        disp(['Simulating tau1 = 3700, tau2 = ' num2str(tau2(j)) '...'])
        [noisy_data data mask beta] = simulate_data([tau1 tau2(j)],t,avg(i),t_irf,irf,200,5);
        disp('Fitting...')
        
        if crop_data == true
            crop = t >= 2000 & t <= 8500;
            noisy_data_crop = noisy_data(crop,:,:);
            t_crop = t(crop);
        end
        
        
        [tau_est, beta_est, I0_est] = fit_test_data(t,noisy_data,mask,[tau1 tau2(j)],t_irf,irf,global_mode,1,200,fit_mode);
        %[tau_est_single, ~, ~] = fit_test_data(t,noisy_data,mask,tau1,t_irf,irf,'single pixel',1,200,0);
          
        tau_est = reshape(tau_est,[2,size(tau_est,2)*size(tau_est,3)]);
        
        te1 = [te1; tau_est(1,:)];
        te2 = [te2; tau_est(2,:)];
            
        est_tau1(i,j) = nanmean(te1);
        est_tau2(i,j) = nanmean(te2);
        
        beta = squeeze(beta(1,:,:));
        beta_est = squeeze(beta_est(1,:,:));
        
        if est_tau1(i,j) < est_tau2(i,j)
            beta_est = 1 - beta_est;
            if fit_mode == 0
                a = est_tau1(i,j);
                est_tau1(i,j) = est_tau2(i,j);
                est_tau2(i,j) = a;
            end
        end
        
        est_beta_map{i,j} = beta_est;
        %est_tau_single_map{i,j} = tau_est_single;
        
        
        beta_est = beta_est(:);
        beta = beta(:); 
        
        est_beta_rms_err(i,j) = sqrt(nanmean((beta-beta_est).^2));
        est_beta_bias(i,j) = nanmean(beta-beta_est);
        
        b = beta(~isnan(beta_est));
        be = beta_est(~isnan(beta_est));
        
        if ~isempty(be)
            est_beta_corr(i,j) = corr(b,be);
        end
                
        disp([i j est_tau1(i,j) est_tau2(i,j) est_beta_rms_err(i,j) est_beta_bias(i,j) est_beta_corr(i,j)])
        
        
    end
end

tau2r = repmat(tau2',[1 length(avg)]);

output = [tau2' (est_tau1-tau1)/tau1 (est_tau2-tau2r)./tau2r est_beta_rms_err est_beta_bias]; 

dlmwrite([f '.csv'],output)
sim_plot_beta_map(est_beta_map,avg,tau2,[0,1],0);
savefig(f,'pdf')

%%
%%-----------------------------------------------------------
% ERROR IN LIFETIME WITH/WITHOUT PULSE TRAIN CORRECTION
%-----------------------------------------------------------

tau = 500:500:2500;
est_tau = zeros(length(avg),length(tau));
for i=1:length(avg)
    for j=1:length(tau)

        [noisy_data data mask] = simulate_data(tau(j),t_tc,avg(i),t_irf_tc,irf_tc,0,0);
        [tau_est, beta_est, I0_est] = fit_test_data(t_tc,noisy_data,mask,tau(j),t_irf_tc,irf_tc,'global',0);

        est_tau(i,j) = nanmean(tau_est(:));
        
        disp([i j est_tau(i,j)])

    end
end

%%

%%-----------------------------------------------------------
% ERROR IN LIFETIME WITH/WITHOUT PULSE TRAIN CORRECTION 
% Single Px fitting
%-----------------------------------------------------------

t = t_wf;
t_irf = t_irf_wf; %t_irf_wf;
irf = irf_wf; %irf_wf;

tau = 500:500:7000;
est_tau = zeros(length(avg),length(tau));
est_tau_std = zeros(length(avg),length(tau));
for i=1:length(avg)
    for j=1:length(tau)
        
        te = [];
        
        for k=1:32 

            [noisy_data data mask] = simulate_data(tau(j),t,avg(i),t_irf,irf,0,0);
            [tau_est, beta_est, I0_est] = fit_test_data(t,noisy_data,mask,tau(j),t_irf,irf,'global',1);
            
            te = [te; tau_est(:)];
        
        end
            
        est_tau(i,j) = nanmean(te);
        est_tau_std(i,j) = nanstd(te);
    
        disp([i j est_tau(i,j) est_tau_std(i,j)])

        
    end
end


%%

tau = [3000 2800];
for i=1:length(avg)
    [noisy_data data mask] = simulate_data(tau,t,avg(i),t_irf_wf,irf_wf,0,0,['sim/tau=3000+2800/photons=' num2str(avg(i),'%06d')]);

    [tau_est, beta_est, I0_est] = fit_test_data(t,noisy_data,mask,tau,t_irf_wf,irf_wf);



end


t = [0 4500 5500 6500 8000 10000 12000];
avg = [200 500 2000 5000 10000];

tau = [3000 2800];
for i=1:length(avg)
    [noisy_data data mask t_irf irf] = simulate_data(tau,t,avg(i),0,0,['sim/tau=3000+2800/photons=' num2str(avg(i),'%06d')]);

    [tau_est, beta_est, I0_est] = fit_test_data(t,noisy_data,mask,tau,t_irf,irf);



end

for i=1:length(avg)
    simulate_data([3000 2000],t,avg(i),0,0,['sim/tau=3000+2000/photons=' num2str(avg(i),'%06d')]);
end

