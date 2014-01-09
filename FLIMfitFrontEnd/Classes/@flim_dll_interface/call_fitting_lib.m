function err = call_fitting_lib(obj,roi_mask,selected)

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

     prof = get_profile();    
   
    
    p = obj.fit_params;
    d = obj.data_series;
    
    if nargin < 3
        selected = [];
    end
    if nargin < 2
        roi_mask = [];
    end

    if d.irf_type == 0 || d.irf_type == 2
        ref_recov = 0; % scatter 
    else
        if p.fit_reference == 0
            ref_recov = 1; % fixed reference
        else
            ref_recov = 2; % fitted
        end
    end
    
    if obj.bin
        n_datasets = 1;
        height = 1;
        width = 1;
        
        [decay,irf] = obj.data_series.get_roi(roi_mask,selected);
        
        n_average = size(decay,3);
        
        decay = squeeze(nanmean(decay,3));
        obj.p_data = libpointer('singlePtr', decay);
        t_skip = [];
        n_t = length(d.tr_t);
        obj.p_t = libpointer('doublePtr',d.tr_t);
        obj.p_mask = libpointer('uint8Ptr',uint8(1));

        obj.p_irf = libpointer('doublePtr', irf);
        
        counts_per_photon = d.counts_per_photon / n_average;
        
        % Only account for smoothing if we only have one pixel - otherwise
        % the effects of smoothing average out over the region
        if n_average == 1
            counts_per_photon = counts_per_photon / (2*d.binning+1)^2;
        end
        
    else
        n_datasets = sum(d.loaded);
        width = d.width;
        height = d.height;
        
        t_skip = d.t_skip;
        n_t = length(d.t);
        obj.p_t = libpointer('doublePtr',d.tr_t_all);
        
        if obj.use_image_irf
            obj.p_irf = libpointer('doublePtr', d.tr_image_irf);
        else
            obj.p_irf = libpointer('doublePtr', d.tr_irf);
        end
        
        if ~isempty(d.seg_mask)        
            m = d.seg_mask;
            obj.p_mask = libpointer('uint8Ptr', uint8(m));
        else
            obj.p_mask = [];
        end
        
        counts_per_photon = d.counts_per_photon;
        
    end
    
    conf_interval = prof.Fitting.Confidence_Interval;
       
    if p.polarisation_resolved
        
        err = calllib(obj.lib_name,'SetupGlobalPolarisationFit', ...
                            obj.dll_id, p.global_algorithm, obj.use_image_irf, ...
                            length(d.tr_irf), obj.p_t_irf, obj.p_irf, 0, obj.p_t0_image, ...
                            p.n_exp, p.n_fix, ...
                            obj.p_tau_min, obj.p_tau_max, p.auto_estimate_tau, obj.p_tau_guess, ...
                            p.fit_beta, obj.p_fixed_beta, ...
                            p.n_theta, p.n_theta_fix, 0, obj.p_theta_guess, ...
                            p.fit_t0, 0, p.fit_offset, p.offset, ...
                            p.fit_scatter, p.scatter, ...
                            p.fit_tvb, p.tvb, obj.p_tvb_profile, ...
                            p.pulsetrain_correction, 1e-6/d.rep_rate, ...
                            ref_recov, d.ref_lifetime, p.fitting_algorithm, p.weighting_mode, ...
                            p.calculate_errs, conf_interval, p.n_thread, true, false, 0);
    else
       
        n_decay_group = max(p.global_beta_group)+1;

        fit_beta = min(p.fit_beta,2);
        
        err = calllib(obj.lib_name,'SetupGlobalFit', ...
                            obj.dll_id, p.global_algorithm, obj.use_image_irf, ...
                            length(d.tr_irf), obj.p_t_irf, obj.p_irf, 0, obj.p_t0_image, ...
                            p.n_exp, p.n_fix, n_decay_group, obj.p_global_beta_group, ...
                            obj.p_tau_min, obj.p_tau_max, p.auto_estimate_tau, obj.p_tau_guess, ...
                            fit_beta, obj.p_fixed_beta, ...
                            p.fit_t0, 0, p.fit_offset, p.offset, ...
                            p.fit_scatter, p.scatter, ...
                            p.fit_tvb, p.tvb, obj.p_tvb_profile, ...
                            p.n_fret, p.n_fret_fix, p.inc_donor, obj.p_E_guess, ...
                            p.pulsetrain_correction, 1e-6/d.rep_rate, ...
                            ref_recov, d.ref_lifetime, p.fitting_algorithm, p.weighting_mode, ...
                            p.calculate_errs, conf_interval, p.n_thread, true, false, 0);
    end

    if err ~= 0
        return;
    end
    
    
    
    data_type = ~strcmp(d.mode,'TCSPC');
    
    % If we're sending a binned decay we don't want it masked!
    if obj.bin
        thresh_min = 0;
    else
        thresh_min = d.thresh_min;
    end
    
    
    calllib(obj.lib_name,'SetDataParams',...
            obj.dll_id, n_datasets, height, width, d.n_chan, n_t, obj.p_t, obj.p_t_int, t_skip, length(d.tr_t),...
            data_type, obj.p_use, obj.p_mask, p.merge_regions, thresh_min, d.gate_max, counts_per_photon, p.global_fitting, d.binning, p.use_autosampling);
 
    if ~isempty(d.acceptor)
        obj.p_acceptor = libpointer('singlePtr', d.acceptor);
        calllib(obj.lib_name,'SetAcceptor',obj.dll_id,obj.p_acceptor)
    end
        
    if err ~= 0
        return;
    end
        
    if ~obj.bin
        if d.background_type == 1
            calllib(obj.lib_name,'SetBackgroundValue',obj.dll_id,d.background_value);
        elseif d.background_type == 2
            obj.p_background = libpointer('singlePtr', d.background_image);
            calllib(obj.lib_name,'SetBackgroundImage',obj.dll_id,obj.p_background);
        elseif d.background_type == 3 && ~isempty(d.tvb_I_image)
            obj.p_background = libpointer('singlePtr', d.tvb_I_image);
            calllib(obj.lib_name,'SetBackgroundTVImage',obj.dll_id,obj.p_tvb_profile_single,obj.p_background,d.background_value);
        end
    end
    
    if ~isempty(obj.p_image_t0_shift)
        calllib(obj.lib_name,'SetImageT0Shift',obj.dll_id,obj.p_image_t0_shift);
    end
        
    if err ~= 0
        return;
    end    
    
    if ishandleandvalid(obj.progress_bar)
        obj.progress_bar.StatusMessage = 'Fitting...';
        obj.progress_bar.Indeterminate = true;
    end
    
    if d.use_memory_mapping && ~obj.bin
        switch(d.data_type)
            case 'uint16'
                data_class = 1;
            case 'single'
                data_class = 0;
        end
        err = calllib(obj.lib_name,'SetDataFile',obj.dll_id,d.mapfile_name,data_class,d.mapfile_offset);
    else
        err = calllib(obj.lib_name,'SetDataFloat',obj.dll_id,obj.p_data);
    end
    
    if err ~= 0
        return;
    end

    err = calllib(obj.lib_name,'StartFit',obj.dll_id);
        

    end