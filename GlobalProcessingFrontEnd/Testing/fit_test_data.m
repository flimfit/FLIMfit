function [tau_est beta_est I0_est] = fit_test_data(t,data,mask,tau_guess,t_irf,irf,mode,ptc,offset,fix)   

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

    if nargin < 7
        mode = 'global';
    end

    if nargin < 8
        ptc = 1;
    end

    if nargin < 9
        offset = 0;
    end
    
    if nargin < 10
        fix = 0;
    end

    n_exp = length(tau_guess);
    n_t = length(t);
    n_irf = length(irf);
    
    t_rep = 1/80e6;

    tau_size = [n_exp size(mask)];
    I0_size = size(mask);

    if strcmp(mode,'single pixel')
        n_group = size(mask,1)*size(mask,2);
        n_px = 1;
        n_regions = ones([1 n_group],'int32');
    else
        n_group = 1;
        n_regions = 1;
        n_px = size(mask,1)*size(mask,2);
    end

    globals_size = [n_group 1];
    
    p_data = libpointer('doublePtr',data);
    p_tau = libpointer('doublePtr', zeros(tau_size));
    p_beta = libpointer('doublePtr', zeros(tau_size));
    p_I0 = libpointer('doublePtr', zeros(I0_size));
    p_t0 = libpointer('doublePtr', zeros(I0_size));
    p_offset = libpointer('doublePtr',zeros(I0_size));
    p_scatter = libpointer('doublePtr',zeros(I0_size));

    p_chi2 = libpointer('doublePtr', zeros(globals_size));
    p_ierr = libpointer('int32Ptr', zeros(globals_size));

    calllib('FLIMGlobalAnalysisDLL','FLIMGlobalFit', ...
                                n_group, n_px, n_regions, 1, ...
                                p_data, mask, ...
                                n_t, t, n_irf, t_irf, irf, ...
                                n_exp, fix, tau_guess, ...
                                0, 0, 0, offset, ...
                                0, 0, 0, 0, ...
                                ptc, t_rep, ...
                                0, 0, 0, ...
                                p_tau, p_I0, p_beta, 0, ...
                                p_t0, p_offset, p_scatter, ...
                                p_chi2, p_ierr, 16, false, false, 0);
                      
    ierr = get(p_ierr,'Value');

    tau_est = reshape(get(p_tau,'Value'),tau_size);
        
    beta_est = reshape(get(p_beta,'Value'),tau_size);
    I0_est = reshape(get(p_I0,'Value'),I0_size);
    
%{
    beta_err = beta_est - beta;
    beta_err_norm = sum(abs(beta_err(:)));

    tau_sq = reshape(tau_est,[n_exp,n_px]);
    tau_sq = mean(tau_sq,2);
    
    disp(['tau = ' mat2str(tau_sq)]);
    disp(['t = ' mat2str(t)]);
    disp(['beta_err_norm = ' num2str(beta_err_norm)]);
   
    di = squeeze(beta_est(1,:,:));
    imagesc(di.^2,'Parent',h);
    colorbar('Peer',h);
    caxis(h,[0 1]);
    pause(0.0001);
    %}
    
    

end
