function transformed_irf = get_irf(obj,varargin)
%> Transform irf depending on the data settings

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

    p = inputParser;
    p.addOptional('t0_shift',0);
    p.addOptional('sigma_override',-1);
    p.parse(varargin{:});
    t0_shift = p.Results.t0_shift;
    sigma_override = p.Results.sigma_override;
    
    
    if numel(obj.g_factor) ~= obj.n_chan
        obj.g_factor = ones(1,obj.n_chan);
    end

    if obj.is_analytical

        shifted_gaussian_parameters = obj.gaussian_parameters;
        t0_shift = obj.t0 + t0_shift;
        for i=1:length(shifted_gaussian_parameters)
            shifted_gaussian_parameters(i).mu = shifted_gaussian_parameters(i).mu + t0_shift;
            if sigma_override > 0
                shifted_gaussian_parameters(i).sigma = sigma_override;
            end
        end

        transformed_irf = analytical_irf(shifted_gaussian_parameters);

    else

        % Determine shift between IRFs
        if obj.polarisation_resolved

            if size(obj.t_irf,1) > 3
                irf_para = obj.irf(:,1);
                irf_perp = obj.irf(:,2);

                [c,lags] = xcorr(irf_perp,irf_para);
                [~,peak] = max(c);
                peak = lags(peak);

                yy = (peak-10):0.01:(peak+10);
                cc = spline(lags,c,yy);

                [~,peak] = max(cc);
                peak = yy(peak);

                dt = (obj.t_irf(2) - obj.t_irf(1));

                peak = peak * dt;

                obj.perp_shift = -peak;
            end
        end

        % Select time points based on threshold
        t_irf_inc = true(size(obj.t_irf));

        tr_image_irf = obj.image_irf;
        tr_irf = obj.irf(t_irf_inc,:);
        tr_t_irf = obj.t_irf(t_irf_inc);

        sz = size(tr_t_irf);
        if sz(1) < sz(2)
            tr_t_irf = tr_t_irf';
        end

        % Calculate coarse shift for perp channel in number of bins
        if length(obj.t_irf) > 1
            dt = obj.t_irf(2) - obj.t_irf(1);
            coarse_shift = round(obj.perp_shift/dt);
        else
            coarse_shift = 0;
        end

        if obj.polarisation_resolved && size(tr_irf,2) == 2
            tr_irf(:,2) = circshift(tr_irf(:,2),[coarse_shift 1]);
        end

        % Subtract background
        clamp = (obj.t_irf < obj.t_irf_min) | (obj.t_irf > obj.t_irf_max);

        bg = obj.irf_background; 

        if ~obj.afterpulsing_correction
            tr_irf = tr_irf - bg;
            tr_irf(tr_irf<0) = 0;
            tr_irf(clamp,:) = 0;

            if obj.has_image_irf
                tr_image_irf = tr_image_irf - bg;
                tr_image_irf(tr_image_irf<0) = 0;
                tr_image_irf(clamp,:) = 0;
            end
        else
            new_bg = bg;
            tr_irf(clamp,:) = new_bg; 
        end

        % Resample IRF 
        %{
        if length(tr_t_irf) > 2 && obj.resample_irf
            irf_spacing = tr_t_irf(2) - tr_t_irf(1);

            if irf_spacing > 75

                interp_min = min(tr_t_irf);
                interp_max = max(tr_t_irf);

                interp_t_irf = interp_min:25:interp_max;

                temp_tr_irf = tr_irf;

                tr_irf = zeros([length(interp_t_irf) obj.n_chan]);

                for i=1:size(tr_irf,2)
                    tr_irf(:,i) = interp1(tr_t_irf,temp_tr_irf(:,i),interp_t_irf,'pchip',0);
                end
                tr_t_irf = interp_t_irf;


            end
        end
        %}

        % TODO: REENABLE T CALIBRATION
        %{
        % use t calibration
        if obj.use_t_calibration && length(tr_t_irf) > 3


            t_cor = interp1(obj.cal_t_nominal,obj.cal_t_meas,tr_t_irf,'pchip',0);

            tr_t_irf = tr_t_irf(1):obj.cal_dt:tr_t_irf(end);

            irf_cor = [];

            for i=1:size(tr_irf,2) 
                ic = interp1(t_cor,tr_irf(:,i),tr_t_irf,'pchip',0);
                irf_cor(:,i) = ic;
            end

            tr_irf = irf_cor;

        end
        %}

        t0_shift = t0_shift + obj.t0;

        dt_irf = obj.t_irf(2)-obj.t_irf(1);
        coarse_shift = round(t0_shift/dt_irf)*dt_irf;
        tr_t_irf = tr_t_irf + coarse_shift;

        remaining_shift = t0_shift-coarse_shift;

        % ensure we have IRF before the data
        if min(tr_t_irf) > obj.data_t_min
            dt = tr_t_irf(2)-tr_t_irf(1);

            diff = tr_t_irf(1) - obj.data_t_min;
            n = ceil(diff/dt) + 1;

            padding = (-n:1:-1)*dt + tr_t_irf(1);

            new_t = [padding'; tr_t_irf];

        else
            new_t = tr_t_irf;
        end


        new_irf = zeros([length(new_t), size(tr_irf,2)]);
        for i=1:size(tr_irf,2)
            new_irf(:,i) = interp1(tr_t_irf,tr_irf(:,i),new_t-remaining_shift,'pchip',0);  
        end

        new_irf(isnan(new_irf)) = 0;
        tr_irf = double(new_irf);
        tr_t_irf = new_t;

        % Normalise irf so it sums to unity
        if size(tr_irf,1) > 0
            for i=1:size(tr_irf,2) 
                sm = sum(tr_irf(:,i));
                if sm > 0
                    tr_irf(:,i) = tr_irf(:,i) / sm;
                end
            end
        end

        if obj.has_image_irf
            sz = size(tr_image_irf);
            tr_image_irf = reshape(tr_image_irf,[sz(1) prod(sz(2:end))]);

            sm = sum(tr_image_irf,1);  
            sm(sm==0) = 1;

            tr_image_irf = bsxfun(@rdivide,tr_image_irf,sm);

            tr_image_irf = reshape(tr_image_irf,sz);
            %{
            for i=1:size(tr_image_irf,2) 
                sm = sum(tr_image_irf(:,i));
                if sm > 0;
                    tr_image_irf(:,i) = tr_image_irf(:,i) / sm;
                end
            end
            %}
        end

        for i=1:size(tr_irf,2)
            tr_irf(:,i) = tr_irf(:,i) * obj.g_factor(i);
        end

        transformed_irf.tr_image_irf = tr_image_irf;
        transformed_irf.irf = tr_irf;
        transformed_irf.t = tr_t_irf;

    end


end
