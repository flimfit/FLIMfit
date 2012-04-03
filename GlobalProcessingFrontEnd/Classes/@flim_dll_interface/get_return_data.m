function get_return_data(obj)

    f = obj.fit_result;
    p = obj.fit_params;
    
    f.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(f.t_exec)]);
    
    if obj.bin
        datasets = 1;
        mask = [];
    else
        datasets = obj.datasets;
        %for i=1:length(datasets)
        %    datasets(i) = sum(obj.data_series.use(1:datasets(i)));
        %end
        mask = obj.data_series.seg_mask;
        if ~isempty(mask)
            flt = obj.data_series.use(obj.data_series.loaded);
            mask = mask(:,:,flt);
        end
    end
    
    
    % get results
    
    if ~isempty(obj.p_chi2)
        chi2 = reshape(obj.p_chi2.Value,obj.I0_size);
        clear obj.p_chi2;
        f.set_image('chi2',chi2,mask,datasets,[0 5]);
    end
    
    if ~isempty(obj.p_tau)
        tau = reshape(obj.p_tau.Value,obj.tau_size);
        clear obj.p_tau;
        if ~isempty(obj.p_tau_err)
            tau_err = reshape(obj.p_tau_err.Value,obj.tau_size);
        else
            tau_err = [];
        end
        f.set_image_split('tau',tau,mask,datasets,[0 4000],tau_err);
        clear obj.p_tau_err tau_err;
    end

    if obj.fit_params.n_exp > 1
        
        if ~isempty(obj.p_beta)
            beta = reshape(obj.p_beta.Value,obj.tau_size);
            clear obj.p_beta;
            f.set_image_split('beta',beta,mask,datasets,[0 1]);
        end

        if ~isempty(obj.p_beta_err)
            beta_err = reshape(obj.p_beta_err.Value,obj.tau_size);
            if ~all(isnan(beta_err(:)))
                f.set_image_split('beta_err',beta_err,mask,datasets,[0 1]);
            end
            clear obj.p_beta_err beta_err;
        end

        if ~isempty(obj.p_tau) && ~isempty(obj.p_beta)
            tau_sqr = tau.*tau;
            mean_tau = sum(tau.*beta,1);
            w_mean_tau = sum(tau_sqr.*beta,1)./mean_tau;
            w_mean_tau = reshape(w_mean_tau,[size(tau,2) size(tau,3) size(tau,4)]);
            mean_tau = reshape(mean_tau,[size(tau,2) size(tau,3) size(tau,4)]);
            f.set_image('mean_tau',mean_tau,mask,datasets,[0 4000]);
            f.set_image('w_mean_tau',w_mean_tau,mask,datasets,[0 4000]);
        end
    
        clear w_mean_tau mean_tau beta tau tau_sqr;
    end
    
    I0 = reshape(obj.p_I0.Value,obj.I0_size);
    f.set_image('I0',I0,mask,datasets,[0 ceil(nanmax(I0(:)))]);
    clear obj.p_I0 I0;
    
    if ~obj.bin
        I = obj.data_series.integrated_intensity();
        I(mask == 0) = NaN;
        f.set_image('I',I,mask,datasets,[0 ceil(nanmax(I(:)))])
        clear I;
    end
    
    
    if obj.fit_params.polarisation_resolved
        
        if prod(obj.theta_size) > 0 && ~isempty(obj.p_theta)
            theta = reshape(obj.p_theta.Value,obj.theta_size);
            if ~isempty(obj.p_theta_err)
                theta_err = reshape(obj.p_theta_err.Value,obj.theta_size);
            else
                theta_err = [];
            end
            f.set_image_split('theta',theta,mask,datasets,[0 4000],theta_err);
            clear obj.p_theta theta theta_terr obj.p_theta_err;
        end
       %{ 
        if prod(obj.theta_size) > 0 && 
            
            f.set_image_split('theta_err',theta_err,mask,datasets,[0 100]);
            clear obj.p_theta_err theta_err;
        end
        %}
        %{
        r = reshape(obj.p_r.Value,obj.r_size);
        if size(r,1) > 1
            f.set_image_split('r',r(1:(end-1),:,:,:),[],[0 1]);
        end
        f.set_image('r_inf',squeeze(r(end,:,:,:)),[],[0 1]);
        clear obj.p_r;
        %}

        r = reshape(obj.p_r.Value,obj.r_size);
        r0 = sum(r,1);
        sz = size(r0);
        sz = sz(2:end);
        if length(sz) == 1
             sz = [sz 1];
        end
        r0 = reshape(r0,sz);
        f.set_image('r_0',r0,mask,datasets,[0 0.4]);
        if size(r,1) > 0
            f.set_image_split('r',r,mask,datasets,[0 0.4]);
        end
        clear obj.p_r r r0;
        
        %{
        r_t = sum(r,1);
        s = size(r_t);
        r_t = reshape(r_t,s(2:end));
        f.set_image('r_0',r_t,[],[0 1]);
        %}
        
        if ~obj.bin
            steady_state = obj.data_series.steady_state_anisotropy();
            steady_state(mask == 0) = NaN;
            f.set_image('r_s',steady_state,mask,datasets,[0 0.4])
        end
    end
    
    
    if obj.fit_params.n_fret > 0
        if ~isempty(obj.p_E)
            E = reshape(obj.p_E.Value,obj.E_size);

            if ~isempty(obj.p_E_err)
                E_err = reshape(obj.p_E_err.Value,obj.E_size);
                clear obj.p_E_err E_err;
            else
                E_err = [];
            end
            
            f.set_image_split('E',E,mask,datasets,[0 1],E_err);
            clear obj.p_E E E_err obj.p_E_err;
        end

            
        gamma = reshape(obj.p_gamma.Value,obj.gamma_size);
        
        if obj.fit_params.inc_donor
            for i=1:size(gamma,1)
                g = gamma(i,:,:,:);
                sz = size(g);
                szg = sz(2:end);
                if length(szg) == 1
                    szg = [szg 1];
                end
                g = reshape(g,szg);
                f.set_image(['gamma_' num2str(i-1)],g,mask,datasets,[0 1]);
            end
        else
            f.set_image_split('gamma',gamma,mask,datasets,[0 1]);
        end
        clear obj.p_gamma gamma;
    end

    if ~isempty(obj.p_offset)
        offset = reshape(obj.p_offset.Value,obj.I0_size);
        f.set_image('offset',offset,mask,datasets,[0 ceil(nanmax(offset(:)))]);
        clear obj.p_offset offset
    end
    
    if ~isempty(obj.p_offset_err)
        offset_err = reshape(obj.p_offset_err.Value,obj.I0_size);
        if ~all(isnan(offset_err(:))) 
            f.set_image('offset_err',offset_err,mask,datasets,[0 ceil(nanmax(offset_err(:)))]);
        end
        clear obj.p_offset_err offset_err
    end
    
    if ~isempty(obj.p_scatter)
        scatter = reshape(obj.p_scatter.Value,obj.I0_size);
        f.set_image('scatter',scatter,mask,datasets,[0 ceil(nanmax(scatter(:)))])
        clear obj.p_scatter scatter
    end
    
    if ~isempty(obj.p_scatter_err)
        scatter_err = reshape(obj.p_scatter_err.Value,obj.I0_size);
        if ~all(isnan(scatter_err(:))) 
            f.set_image('scatter_err',scatter_err,mask,datasets,[0 ceil(nanmax(scatter_err(:)))])
        end
        clear obj.p_scatter_err scatter_err
    end
    
    if ~isempty(obj.p_tvb)
        tvb = reshape(obj.p_tvb.Value,obj.I0_size);
        f.set_image('tvb',tvb,mask,datasets,[0 ceil(nanmax(tvb(:)))])
        clear obj.p_tvb tvb
    end
    
    if ~isempty(obj.p_tvb_err)
        tvb_err = reshape(obj.p_tvb_err.Value,obj.I0_size);
        if ~all(isnan(tvb_err(:))) 
            f.set_image('tvb_err',tvb_err,mask,datasets,[0 ceil(nanmax(tvb_err(:)))])
        end
        clear obj.p_tvb_err tvb_err
    end
    
    %{
    if ~isempty(obj.p_t0)
        t0 = reshape(obj.p_t0.Value,obj.I0_size);
        f.set_image('t0',t0,mask,datasets,[0 nanmax(t0(:))]);
        clear obj.p_t0 t0;
    end
    %} 
    
    if ~isempty(obj.p_ref_lifetime)
        ref_lifetime = reshape(obj.p_ref_lifetime.Value,obj.I0_size);
        f.set_image('ref_lifetime',ref_lifetime,mask,datasets,[0 1000]);
        clear obj.p_ref_lifetime ref_lifetime;
    end
    
    if ~isempty(obj.p_ref_lifetime_err)
        ref_lifetime_err = reshape(obj.p_ref_lifetime_err.Value,obj.I0_size);
        if ~all(isnan(ref_lifetime_err(:))) 
            f.set_image('ref_lifetime_err',ref_lifetime_err,mask,datasets,[0 100]);
        end
        clear obj.p_ref_lifetime_err ref_lifetime_err;
    end
    
    %if ~isempty(mask)   
    %    f.set_image('mask',mask,mask,datasets,[0 nanmax(mask(:))]);
    %end
    
    if obj.fit_params.global_fitting == 0
        ierr = reshape(obj.p_ierr.Value,obj.I0_size);
        f.set_image('ierr',double(ierr),mask,datasets,[-10 200]);
    end
    
    
    f.has_grid = obj.grid;
    
    if obj.grid
        f.grid = reshape(obj.p_grid.Value,obj.grid_dims);
    end
    
    ierr = reshape(obj.p_ierr.Value,obj.globals_size);
    clear obj.p_ierr
    
    for i=1:length(datasets)
       if p.global_fitting < 2
           r_start = 1+sum(obj.n_regions(1:i-1));
           r_end = r_start + obj.n_regions(i)-1;
       else
           r_start = 1;
           r_end = obj.n_regions(1);
       end
           
       if r_end < r_start
           f.ierr(datasets(i)) = 0;
           f.iter(datasets(i)) = 0;
           f.success(datasets(i)) = 100;
       else
           if p.global_fitting == 0
               ierrd = ierr(:,:,r_start:r_end);
           elseif p.global_fitting == 1
               ierrd = ierr(r_start:r_end);
           else
               ierrd = ierr;
           end

           ierrs = double(ierrd(ierrd<0));
           if isempty(ierrs)
               ierrs = 0;
           else
               ierrs = mode(ierrs);
           end

           f.ierr(datasets(i)) = ierrs;
           f.iter(datasets(i)) = sum(ierrd(ierrd>=0));
           f.success(datasets(i)) = sum(ierrd(:)>=0)/length(ierrd(:)) * 100;
           
       end

    end
    clear ierr       
end