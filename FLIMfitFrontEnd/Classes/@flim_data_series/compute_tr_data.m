function calculated = compute_tr_data(obj,notify_update,no_smoothing)
%> Transform data based on settings
    
    
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

    if nargin < 2
        notify_update = true;
    end
    
    if nargin < 3
        no_smoothing = ~obj.use_smoothing;
    end

    calculated = false;
    
    if obj.init && ~obj.suspend_transformation
        
        % arbitrary size threshold
        d_size = obj.data_size;
        if prod(d_size) > 16e6 && ~no_smoothing
            wbar = waitbar(1,'Transforming! Please wait...');
        else
            wbar = [];
        end

        calculated = true;

        % use t calibration
        if obj.use_t_calibration && length(obj.t) > 1
        
            t_cor = interp1(obj.cal_t_nominal,obj.cal_t_meas,obj.t,'pchip');
            dt = obj.cal_dt;
            
            t_cor_round = t_cor/dt;
            t_cor_round = round(t_cor_round)*dt;
            
            obj.tr_t_all = t_cor_round;
        else
            obj.tr_t_all = obj.t;     
        end
        
        
        % Crop timegates  
        t_inc = obj.tr_t_all >= obj.t_min & obj.tr_t_all <= obj.t_max;
        

        % If there is a IRF ensure that we don't have data points before the IRF
        %if ~isempty(obj.tr_t_irf)
        %    t_inc = t_inc & obj.t >= min(obj.tr_t_irf);
        %end
        
        % For polarisation resolved data, attempt to line up the two
        % polarisation channels to within a timegate. This allows the user
        % to sensibly crop the data
        if length(obj.t) > 1
            dt = obj.t(2) - obj.t(1);
            coarse_shift = round(obj.irf_perp_shift/dt);      
        else
            coarse_shift = 0;
        end
        
        if coarse_shift < 0
           t_inc(end+coarse_shift:end) = 0;            
        elseif coarse_shift > 0
           t_inc(1:coarse_shift) = 0; 
        end
        
        t_inc_perp = circshift(t_inc,[1 -coarse_shift]);

        % If shifting the perp channel pushes us over the edge crop both 
        % data channels
        if sum(t_inc_perp) < sum(t_inc)
            if obj.irf_perp_shift < 0
               n = find(t_inc_perp, 1, 'first') - 2;
               t_inc(end-n:end) = 0;             
            else
               n = length(t_inc_perp) - find(t_inc_perp, 1, 'last');
               t_inc(1:n) = 0;
            end
        end
        
        if obj.data_subsampling > 1
            subs = 1:length(t_inc);
            subs = mod(subs,obj.data_subsampling) == 1;

            t_inc = t_inc & subs;
        end
        
        
        obj.t_skip = [find(t_inc,1,'first') find(t_inc_perp,1,'first')]-1;
        
        % Apply all the masking above
        obj.tr_t = obj.tr_t_all(t_inc);
        obj.tr_t_int = obj.t_int(t_inc);
        
        obj.tr_t_int = obj.tr_t_int / min(obj.tr_t_int);

            
        obj.cur_tr_data = single(obj.cur_data);
        %{
        if isfield(obj.metadata,'ACC') && ~isempty(obj.metadata.ACC{obj.active})
            acum = obj.metadata.ACC{obj.active};
            if ischar(acum)
                acum = str2num(acum);
            end
            obj.cur_tr_data = obj.cur_tr_data / acum;
        end
        %}

        
        % Subtract background and crop
        bg = obj.background;
        if length(bg) == 1 || all(size(bg)==size(obj.cur_tr_data))
            obj.cur_tr_data = obj.cur_tr_data - single(bg);
        end
        
        if true || strcmp(obj.mode,'TCSPC') || obj.n_t == 1
            in = sum(obj.cur_tr_data,1);
        else
            in = trapz(obj.t,obj.cur_tr_data,1)/1000;
        end
        
        %if obj.polarisation_resolved
        %    in = in(1,1,:,:) + in(1,2,:,:); % 2*obj.g_factor*
        %end
     
        in = sum(in,2);
         obj.intensity = squeeze(in);
        

        
        % Shift the perpendicular channel and crop in time
        tmp = obj.cur_tr_data(t_inc,1,:,:);
        if obj.polarisation_resolved
            tmp(:,2,:,:) = obj.cur_tr_data(t_inc_perp,2,:,:);
        end
        obj.cur_tr_data = tmp;

        % Smooth data
        if obj.binning > 0 && ~no_smoothing
            obj.cur_tr_data = obj.smooth_flim_data(obj.cur_tr_data,obj.binning);
        end

       
        obj.cur_smoothed = ~no_smoothing;
        
        obj.compute_tr_irf();
        
        obj.compute_intensity();
        obj.compute_tr_tvb_profile();  
        
        if notify_update
            notify(obj,'data_updated');
        end
        
        if ~isempty(wbar)
            close(wbar);
        end
        
    end
end