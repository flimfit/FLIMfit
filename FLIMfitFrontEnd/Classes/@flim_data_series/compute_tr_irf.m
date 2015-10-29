function compute_tr_irf(obj)
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


    if obj.init

        % If we've got polarisation resolved data but only one irf
        % repeat over both channels
        if obj.polarisation_resolved && size(obj.irf,2) == 1
            obj.irf = repmat(obj.irf,[1 obj.n_chan]);
        end

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

                obj.irf_perp_shift = -peak;

            end

        end
        
        % Select time points based on threshold
        t_irf_inc = true(size(obj.t_irf));

        % Subsample if required
        if obj.irf_subsampling > 1
            subs = 1:length(t_irf_inc);
            subs = mod(subs',obj.irf_subsampling) == 1;

            t_irf_inc = t_irf_inc & subs;
        end
        
        obj.tr_image_irf = obj.image_irf;
        obj.tr_irf = obj.irf(t_irf_inc,:);
        obj.tr_t_irf = obj.t_irf(t_irf_inc);

        % Calculate coarse shift for perp channel in number of bins
        if length(obj.t) > 1
            dt = obj.t(2) - obj.t(1);
            coarse_shift = round(obj.irf_perp_shift/dt);
        else
            coarse_shift = 0;
        end
        
        if obj.polarisation_resolved && size(obj.tr_irf,2) == 2
            obj.tr_irf(:,2) = circshift(obj.tr_irf(:,2),[coarse_shift 1]);
        end

        % Subtract background
        clamp = (obj.t_irf < obj.t_irf_min) | (obj.t_irf > obj.t_irf_max);

        if length(obj.irf_background) == 2
            bg = reshape(obj.irf_background,[1,2]);
            bg = repmat(bg,[length(obj.tr_t_irf),1]);
        else
            bg = obj.irf_background; %repmat(obj.irf_background,[length(obj.tr_t_irf),size(obj.tr_irf,2)]);
        end

        if ~obj.afterpulsing_correction
            obj.tr_irf = obj.tr_irf - bg;
            obj.tr_irf(obj.tr_irf<0) = 0;
            obj.tr_irf(clamp,:) = 0;
            
            if obj.has_image_irf
                obj.tr_image_irf = obj.tr_image_irf - bg;
                obj.tr_image_irf(obj.tr_image_irf<0) = 0;
                obj.tr_image_irf(clamp,:) = 0;
            end
        else
            new_bg = bg;
            z = (obj.tr_irf < bg);
            %obj.tr_irf(z) = new_bg;
            obj.tr_irf(clamp,:) = new_bg; 
        end

        % Resample IRF 
        if length(obj.tr_t_irf) > 2 && obj.resample_irf
            irf_spacing = obj.tr_t_irf(2) - obj.tr_t_irf(1);

            if irf_spacing > 75

                interp_min = min(obj.tr_t_irf);
                interp_max = max(obj.tr_t_irf);

                interp_t_irf = interp_min:25:interp_max;

                temp_tr_irf = obj.tr_irf;

                obj.tr_irf = zeros([length(interp_t_irf) obj.n_chan]);

                for i=1:size(obj.tr_irf,2)
                    obj.tr_irf(:,i) = interp1(obj.tr_t_irf,temp_tr_irf(:,i),interp_t_irf,'pchip',0);
                end
                obj.tr_t_irf = interp_t_irf;


            end
        end
        
        % Deconvolve decay from reference if required
        if (obj.irf_type == 2)
            ir = obj.tr_irf(:);
            
            p = 5;
            
            s = length(obj.tr_irf);
            
            padding = zeros(p*s,1);
            
            ir = [padding; ir; padding]; 
            
            s = length(obj.tr_irf);
            
            %dt = obj.tr_t_irf(2)-obj.tr_t_irf(1);
            %t2 = (0:(2*s-1))*dt + min(obj.tr_t_irf);
            %t2 = t2';
            T = 1e6/obj.rep_rate;
            t2 = obj.tr_t_irf(:) - min(obj.tr_t_irf);
            decay = exp(-(t2/obj.ref_lifetime))*(1+1/(exp(T/obj.ref_lifetime)-1));
            decay = decay(decay>1e-8);
            decay = [zeros(size(decay)); decay];
            
            ir = edgetaper(ir,decay); 
            ir = deconvlucy(ir,decay,20);
            
            %ir = deconvwnr(ir,decay,1);
            
            start = p*s+1;
            finish = start + s - 1;
              
            obj.tr_irf = ir(start:finish);
            
            dt = obj.tr_t_irf(2)-obj.tr_t_irf(1);
            t0_correction = -0.5*dt;
        else
            t0_correction = 0;
        end
           
        % use t calibration
        if obj.use_t_calibration && length(obj.tr_t_irf) > 3

            
            t_cor = interp1(obj.cal_t_nominal,obj.cal_t_meas,obj.tr_t_irf,'pchip',0);

            obj.tr_t_irf = obj.tr_t_irf(1):obj.cal_dt:obj.tr_t_irf(end);

            irf_cor = [];
            
            for i=1:size(obj.tr_irf,2) 
                ic = interp1(t_cor,obj.tr_irf(:,i),obj.tr_t_irf,'pchip',0);
                irf_cor(:,i) = ic;
            end
            
            obj.tr_irf = irf_cor;

        end
        
        if obj.use_image_t0_correction
            t0_shift = -obj.metadata.t0{obj.active};
        else
            t0_shift = 0;
        end
        
        % Shift by t0
        t0_shift = t0_shift+obj.t0-t0_correction;
        
        
        dt_irf = obj.t_irf(2)-obj.t_irf(1);
        coarse_shift = round(t0_shift/dt_irf)*dt_irf;
        obj.tr_t_irf = obj.tr_t_irf + coarse_shift;
                      
        remaining_shift = t0_shift-coarse_shift;
        
        % ensure we have IRF before the data
        if min(obj.tr_t_irf) > min(obj.t) %|| min(obj.tr_t_irf) > min(obj.tr_t_all)
            dt = obj.tr_t_irf(2)-obj.tr_t_irf(1);
            
            diff = obj.tr_t_irf(1) - obj.t(1);
            n = ceil(diff/dt) + 1;
            
            padding = (-n:1:-1)*dt + obj.tr_t_irf(1);
        
            new_t = [padding'; obj.tr_t_irf];
            
        else
            new_t = obj.tr_t_irf;
        end
            
        
        
        for i=1:size(obj.tr_irf,2)
            new_irf(:,i) = interp1(obj.tr_t_irf,obj.tr_irf(:,i),new_t-remaining_shift,'pchip',0);  
        end
        
        new_irf(isnan(new_irf)) = 0;
        obj.tr_irf = new_irf;
        obj.tr_t_irf = new_t;
        
        % Normalise irf so it sums to unity
        if size(obj.tr_irf,1) > 0
            for i=1:size(obj.tr_irf,2) 
                sm = sum(obj.tr_irf(:,i));
                if sm > 0;
                    obj.tr_irf(:,i) = obj.tr_irf(:,i) / sm;
                end
            end
        end
        

        
        
        %figure(3);
        
        %plot(obj.tr_t_irf,ir);
        
        if obj.has_image_irf
            sz = size(obj.tr_image_irf);
            obj.tr_image_irf = reshape(obj.tr_image_irf,[sz(1) prod(sz(2:end))]);

            sm = sum(obj.tr_image_irf,1);  
            sm(sm==0) = 1;
            
            %replace genops with bsxfun
            obj.tr_image_irf = bsxfun(@rdivide,obj.tr_image_irf,sm);
            %obj.tr_image_irf = obj.tr_image_irf ./ sm;
            
            obj.tr_image_irf = reshape(obj.tr_image_irf,sz);
            %{
            for i=1:size(obj.tr_image_irf,2) 
                sm = sum(obj.tr_image_irf(:,i));
                if sm > 0;
                    obj.tr_image_irf(:,i) = obj.tr_image_irf(:,i) / sm;
                end
            end
            %}
        end
        
        if obj.polarisation_resolved
            obj.tr_irf(:,1) = obj.tr_irf(:,1) * obj.g_factor;
        end
        
        %sz = size(obj.tr_image_irf);
        %obj.tr_image_irf = repmat(obj.tr_irf,[1 1 sz(3) sz(4)]);



    end
end