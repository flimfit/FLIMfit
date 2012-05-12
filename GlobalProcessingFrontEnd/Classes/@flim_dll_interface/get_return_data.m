function get_return_data(obj)

    f = obj.fit_result;
    p = obj.fit_params;
    d = obj.data_series;
    
    f.t_exec = toc(obj.start_time);    
    disp(['DLL execution time: ' num2str(f.t_exec)]);
        
    if obj.bin
        datasets = 1;
        mask = 1;
    else
        datasets = obj.datasets;
        mask = d.seg_mask;
        flt = obj.use;
        if ~isempty(mask)
            mask = mask(:,:,flt);
        else
            mask = ones(d.height,d.width,sum(flt));
        end
    end
        
    % Setup memory to retrieve fit data
    if obj.bin
        sz = [1 1];
    else
        sz = [d.height d.width];
    end
    
    max_n_regions = max(obj.n_regions);
    
    I0_size = sz;
    
    if p.global_fitting == 0
        g_size = sz;
        tau_size = [sz p.n_exp];
        theta_size = [p.n_theta max_n_regions];
        E_size = [sz p.n_fret];
    else
        g_size = [1 max_n_regions];
        tau_size = [p.n_exp max_n_regions];
        theta_size = [p.n_theta max_n_regions];
        E_size = [p.n_fret max_n_regions];
    end
    
    if p.fit_beta == 1 || p.global_fitting == 0
        beta_size = [sz p.n_exp];
    else
        beta_size = [p.n_exp max_n_regions];
    end
    
    n_decay_group = p.n_fret + p.inc_donor;
    gamma_size = [sz n_decay_group];
    r_size = [sz p.n_theta];
    
    if p.fit_offset == 2 && p.global_fitting > 0
        offset_size = g_size;
    else
        offset_size = I0_size;
    end
    
    if p.fit_scatter == 2 && p.global_fitting > 0
        scatter_size = g_size;
    else
        scatter_size = I0_size;
    end
    
    if p.fit_tvb == 2 && p.global_fitting > 0
        tvb_size = g_size;
    else
        tvb_size = I0_size;
    end
    
    
    if p.polarisation_resolved
        p_r = libpointer('doublePtr',zeros(r_size));
        p_theta = libpointer('doublePtr',zeros(theta_size));

        p_E = [];
        p_gamma = [];
    else
        p_E = libpointer('doublePtr',zeros(E_size));
        p_gamma = libpointer('doublePtr',zeros(gamma_size));

        p_r = [];
        p_theta = [];
    end


    p_tau = libpointer('doublePtr', zeros(tau_size));
    
    if p.n_exp > 1
        p_beta = libpointer('doublePtr', zeros(beta_size));
    else
        p_beta = [];
    end
    
    p_I0 = libpointer('doublePtr', zeros(I0_size));

    if false
        p_t0 = libpointer('doublePtr', zeros(I0_size));
    else
        p_t0 = [];
    end

    if p.fit_offset > 0
        p_offset = libpointer('doublePtr',zeros(offset_size));
    else
        p_offset = [];
    end

    if p.fit_scatter > 0
        p_scatter = libpointer('doublePtr',zeros(scatter_size));
    else
        p_scatter = [];
    end

    if p.fit_tvb > 0
        p_tvb = libpointer('doublePtr',zeros(tvb_size));
    else
          p_tvb = [];
    end

    if p.ref_reconvolution == 2
        p_ref_lifetime = libpointer('doublePtr',zeros(I0_size));
    else
        p_ref_lifetime = [];
    end

    p_tau_err = [];
    p_beta_err = [];
    p_theta_err = [];
    p_E_err = [];
    p_offset_err = [];
    p_scatter_err = [];
    p_tvb_err = [];
    p_ref_lifetime_err = [];

    if p.calculate_errs && ~obj.bin
        p_tau_err = libpointer('doublePtr', zeros(tau_size));

        if p.fit_beta == 2
            p_beta_err = libpointer('doublePtr',zeros(tau_size));
        end

        if p.polarisation_resolved
            p_theta_err = libpointer('doublePtr',zeros(theta_size));
        else
            p_E_err = libpointer('doublePtr',zeros(E_size));
        end

        if p.fit_offset == 2
            p_offset_err = libpointer('doublePtr',zeros(I0_size));
        end
        if p.fit_scatter == 2
            p_scatter_err = libpointer('doublePtr',zeros(I0_size));
        end
        if p.fit_tvb == 2
            p_tvb_err = libpointer('doublePtr',zeros(I0_size));
        end
        if p.ref_reconvolution == 2
           p_ref_lifetime_err = libpointer('doublePtr', zeros(I0_size));
        end
    end

    p_chi2 = libpointer('doublePtr', zeros(I0_size));

    
    ierr = reshape(obj.p_ierr.Value,obj.globals_size);
    clear obj.p_ierr
    
    stop = false;
    wh = waitbar(0, 'Processing fit results...','CreateCancelBtn','setappdata(gcbf,''canceling'',1);');
    
    setappdata(wh,'canceling',0);
    
    % Get results for each image
    for i = 1:length(datasets)
    
        if getappdata(wh,'canceling');
            break;
            datasets = datasets(1:(i-1));
        end
        
        im = datasets(i);
        
        if p.global_fitting < 2
           r_start = 1+sum(obj.n_regions(1:i-1));
           r_end = r_start + obj.n_regions(i)-1;
       else
           r_start = 1;
           r_end = obj.n_regions(1);
        end
        
        if (obj.n_regions(i) > 0)
            % Retrieve results
            err = calllib(obj.lib_name,'GetResults', ...
                          obj.dll_id, i-1, p_chi2, p_tau, p_I0, p_beta, p_E, p_gamma, ...
                          p_theta, p_r, p_t0, p_offset, p_scatter, p_tvb, p_ref_lifetime);

            dmask = mask(:,:,i);
            min_region = min(dmask(dmask>0)) ;

            if ~isempty(p_chi2)
                chi2 = reshape(p_chi2.Value,I0_size);
                if ~obj.bin
                    dmask(isnan(chi2)) = 0;
                end
                f.set_image('chi2',chi2,dmask,im,[0 5]);
                clear chi2;
            end

            if ~isempty(p_tau)
                tau = reshape(p_tau.Value,tau_size);
                tau = obj.fill_image(tau,dmask,min_region);
                if ~isempty(p_tau_err)
                    tau_err = reshape(p_tau_err.Value,tau_size);
                else
                    tau_err = [];
                end
                f.set_image_split('tau',tau,dmask,im,[0 4000],tau_err);

            end

            if obj.fit_params.n_exp > 1

                if ~isempty(p_beta)
                    beta = reshape(p_beta.Value,beta_size);
                    beta = obj.fill_image(beta,dmask,min_region);
                    f.set_image_split('beta',beta,dmask,im,[0 1]);
                end

                if ~isempty(p_beta_err)
                    beta_err = reshape(p_beta_err.Value,beta_size);
                    if ~all(isnan(beta_err(:)))
                        f.set_image_split('beta_err',beta_err,dmask,im,[0 1]);
                    end

                end

                if ~isempty(p_tau) && ~isempty(p_beta)
                    tau_sqr = tau.*tau;
                    ds = length(size(tau));
                    mean_tau = sum(tau.*beta,ds);
                    w_mean_tau = sum(tau_sqr.*beta,ds)./mean_tau;
                    w_mean_tau = reshape(w_mean_tau,[size(tau,1) size(tau,2)]);
                    mean_tau = reshape(mean_tau,[size(tau,1) size(tau,2)]);
                    f.set_image('mean_tau',mean_tau,dmask,im,[0 4000]);
                    f.set_image('w_mean_tau',w_mean_tau,dmask,im,[0 4000]);
                end
            end

            clear tau beta mean_tau w_mean_tau
            
            I0 = reshape(p_I0.Value,I0_size);
            f.set_image('I0',I0,dmask,im,[0 ceil(nanmax(I0(:)))]);
            clear I0;

            if ~obj.bin
                I = obj.data_series.integrated_intensity(datasets(i));
                I(dmask == 0) = NaN;
                f.set_image('I',I,dmask,im,[0 ceil(max(I(:)))])
                clear I;
            end


            if obj.fit_params.polarisation_resolved

                if prod(theta_size) > 0 && ~isempty(p_theta)
                    theta = reshape(p_theta.Value,theta_size);
                    theta = obj.fill_image(theta,dmask,min_region);
                    if ~isempty(p_theta_err)
                        theta_err = reshape(p_theta_err.Value,theta_size);
                    else
                        theta_err = [];
                    end
                    f.set_image_split('theta',theta,dmask,im,[0 4000],theta_err);

                end
               %{ 
                if prod(obj.theta_size) > 0 && 

                    f.set_image_split('theta_err',theta_err,dmask,im,[0 100]);
                    clear p_theta_err theta_err;
                end
                %}
                %{
                r = reshape(p_r.Value,obj.r_size);
                if size(r,1) > 1
                    f.set_image_split('r',r(1:(end-1),:,:,:),[],[0 1]);
                end
                f.set_image('r_inf',squeeze(r(end,:,:,:)),[],[0 1]);
                clear p_r;
                %}

                r = reshape(p_r.Value,r_size);
                r0 = sum(r,3);
                sz = size(r0);
                sz = sz(1:2);
                if length(sz) == 1
                     sz = [sz 1];
                end
                r0 = reshape(r0,sz);
                f.set_image('r_0',r0,dmask,im,[0 0.4]);
                if size(r,1) > 0
                    f.set_image_split('r',r,dmask,im,[0 0.4]);
                end


                if ~obj.bin
                    steady_state = obj.data_series.steady_state_anisotropy(datasets(i));
                    steady_state(mask == 0) = NaN;
                    f.set_image('r_s',steady_state,dmask,im,[0 0.4])
                end
            end


            if obj.fit_params.n_fret > 0
                if ~isempty(p_E)
                    E = reshape(p_E.Value,E_size);
                    E = obj.fill_image(E,dmask,min_region);

                    if ~isempty(p_E_err)
                        E_err = reshape(p_E_err.Value,E_size);

                    else
                        E_err = [];
                    end

                    f.set_image_split('E',E,dmask,im,[0 1],E_err);

                end


                gamma = reshape(p_gamma.Value,gamma_size);

                if obj.fit_params.inc_donor
                    for i=1:size(gamma,3)
                        g = gamma(:,:,i);
                        f.set_image(['gamma_' num2str(i-1)],g,dmask,im,[0 1]);
                    end
                else
                    f.set_image_split('gamma',gamma,dmask,im,[0 1]);
                end

            end

            if ~isempty(p_offset)
                offset = reshape(p_offset.Value,offset_size);
                offset = obj.fill_image(offset,dmask,min_region);
                f.set_image('offset',offset,dmask,im,[0 ceil(nanmax(offset(:)))]);

            end

            if ~isempty(p_offset_err)
                offset_err = reshape(p_offset_err.Value,I0_size);
                if ~all(isnan(offset_err(:))) 
                    f.set_image('offset_err',offset_err,dmask,im,[0 ceil(nanmax(offset_err(:)))]);
                end

            end

            if ~isempty(p_scatter)
                scatter = reshape(p_scatter.Value,obj.scatter_size);
                scatter = obj.fill_image(scatter,dmask,min_region)
                f.set_image('scatter',scatter,dmask,im,[0 ceil(nanmax(scatter(:)))])
            end

            if ~isempty(p_scatter_err)
                scatter_err = reshape(p_scatter_err.Value,I0_size);
                if ~all(isnan(scatter_err(:))) 
                    f.set_image('scatter_err',scatter_err,dmask,im,[0 ceil(nanmax(scatter_err(:)))])
                end

            end

            if ~isempty(p_tvb)
                tvb = reshape(p_tvb.Value,I0_size);
                tvb = obj.fill_image(tvb,dmask,min_region);
                f.set_image('tvb',tvb,dmask,im,[0 ceil(nanmax(tvb(:)))])

            end

            if ~isempty(p_tvb_err)
                tvb_err = reshape(p_tvb_err.Value,tvb_size);
                if ~all(isnan(tvb_err(:))) 
                    f.set_image('tvb_err',tvb_err,dmask,im,[0 ceil(nanmax(tvb_err(:)))])
                end

            end

            %{
            if ~isempty(p_t0)
                t0 = reshape(p_t0.Value,obj.I0_size);
                f.set_image('t0',t0,dmask,im,[0 nanmax(t0(:))]);
                clear p_t0 t0;
            end
            %} 

            if ~isempty(p_ref_lifetime)
                ref_lifetime = reshape(p_ref_lifetime.Value,I0_size);
                f.set_image('ref_lifetime',ref_lifetime,dmask,im,[0 1000]);

            end

            if ~isempty(p_ref_lifetime_err)
                ref_lifetime_err = reshape(p_ref_lifetime_err.Value,I0_size);
                if ~all(isnan(ref_lifetime_err(:))) 
                    f.set_image('ref_lifetime_err',ref_lifetime_err,dmask,im,[0 100]);
                end
            end

            if obj.fit_params.global_fitting == 0
                f.set_image('ierr',double(ierr(:,:,i)),dmask,im,[-10 200]);
            end
            
            
        end
     
        if mod(i,10)
            waitbar(i/length(datasets),wh);
        end
    end
            
    if ishandle(wh)
        delete(wh);
    end
    
    clear p_chi2;
    clear p_tau p_tau_err p_beta p_beta_err;
    clear p_ref_lifetime;
    clear p_ref_lifetime_err;
    clear p_tvb_err tvb_err
    clear p_tvb
    clear p_theta p_theta_err p_r p_E p_E_err p_gamma p_scatter p_scatter_err clear p_offset_err p_offset
    clear p_I0 p_E_err;

    
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
               ierrd = ierr(:,:,i);
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