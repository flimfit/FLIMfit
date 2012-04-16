classdef flim_data_series < handle
   
    properties
        mode;
        
        t_irf = [-1; 0; 1];
        irf = [0; 1; 0];
        irf_name;
               
        counts_per_photon;
        
        tvb_profile = 0;
          
        subtract_background = false;

        min = 0;
        max = 0;        
    end
    
    properties(Constant)
        resample_irf = false;    
        normalise_irf = false;
        data_settings_filename = {'data_settings.xml', 'polarisation_data_settings.xml'};
    end
    
    properties(SetObservable)
        binning = 1;
        downsampling = 1;
        t_min = 0;
        t_max = 0;
        thresh_min = 0;
        gate_max = 2^16-1;
        t_irf_min = 0;
        t_irf_max = 0;
        irf_background = 0;
        irf_downsampling = 1;
        g_factor = 1;
        afterpulsing_correction = false;

        background_type = 0;
        background_value = 0;
        
        t0 = 0;
    end
    
    properties(Dependent)
        width;
        height;
        n_datasets;
        n_masked;
               
        background;
        
        im_size;
        n_t;
    end
    
    properties(SetObservable,Transient)
        suspend_transformation = false;
        n_chan = 1;
        polarisation_resolved = false;
        data_size;
        use;
    end
        
    
    properties(Transient)
        raw = false;
        
        use_memory_mapping = true;
        load_multiple_channels = false;
        
        tr_data_series_mem;
        data_series_mem;
        
        mapfile_name;
        memmap;
        mapfile_offset = 0;
                
        cur_data;
        cur_tr_data;
                
        root_path;
        
        intensity = [];
        mask = [];
        thresh_mask = [];
                
        t;   
        
        tr_t_irf;
        tr_irf;
        
        t_skip;
        
        irf_perp_shift = 0;

        tr_t;
        
        tr_tvb_profile;
        
        names;
        metadata;

        tr_data_size;
        num_datasets;
        
        init = false;

        seg_mask = [];
        
        background_image = 0;
        
        use_popup = true;  
        lazy_loading = false;
        
        file_names;
        channels;
        
        loaded = [];
        load_time = [];
        
        active = 0;
    end
    
    events
        data_updated;
        masking_updated;
        selection_updated;
    end
    
    methods(Static)
        
        data = smooth_flim_data(data,extent,mode)
        [n_chan, chan_info] = get_channels(FileName)
             
        function data = ensure_correct_dimensionality(data)
            %> Ensure that data has singleton dimension for polarisation
            s = size(data);
            if length(s) == 3
                data = reshape(data,[s(1) 1 s(2) s(3)]);
            end
        end
        
        function channel = request_channels(polarisation_resolved)
            %> Request which channels to use from dataset via dialog box
            if polarisation_resolved
                dlgTitle = 'Select channels';
                prompt = {'Parallel Channel';'Perpendicular Channel'};
                defaultvalues = {'1','2'};
                numLines = 1;
                inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                channel = uint32(str2double(inputdata));
            else
                dlgTitle = 'Select channel';
                prompt = {'Channel '};
                defaultvalues = {'1'};
                numLines = 1;
                inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                channel = uint32(str2double(inputdata{1}));
            end
       end
        
    end
    
    methods
        
        
        %===============================================================

        function obj = flim_data_series()
            
            del_files = dir([tempdir 'GPTEMP_*']);
            
            warning('off','MATLAB:DELETE:Permission');
            
            for i=1:length(del_files)
                try
                   delete([tempdir del_files(i).name]); 
                catch e %#ok
                end
            end
            
            warning('on','MATLAB:DELETE:Permission');
            
        end
        
        
        %===============================================================
        
        function load_data_settings(obj,file)
            %> Load data setting file 
            obj.suspend_transformation = true;
            marshal_object(file,'flim_data_series',obj);
            notify(obj,'masking_updated');
            obj.suspend_transformation = false;
        end
        
        function file = save_data_settings(obj,file)
            %> Save data setting file
            file = [];
            if obj.init
                if nargin < 2
                    pol_idx = obj.polarisation_resolved + 1;
                    file = [obj.root_path obj.data_settings_filename{pol_idx}];
                end

                serialise_object(obj,file);
            end
        end
        
        function reload_data(obj)
            l = 1:obj.num_datasets;
            obj.loaded(:) = false;
            obj.load_selected_files(l);
        end
        %===============================================================
        
        function data = get_roi(obj,roi_mask,dataset)
            %> Return an array of data points both in internal mask
            %> and roi_mask from dataset selected
            
            obj.switch_active_dataset(dataset);
            
            n_tr_t = length(obj.tr_t);
            
            idx = obj.get_intensity_idx(dataset);
            
            % Get mask from thresholding
            m = (obj.mask > 0);
            
            % Combine with segmentation mask, if it exists
            if ~isempty(obj.seg_mask)
               m = m & obj.seg_mask(:,:,idx) > 0; 
            end
            
            % Then roi_mask
            if ~isempty(roi_mask)
                roi_mask = roi_mask & m;
            else
                roi_mask = m;
            end
            
            % Get data

            data = obj.cur_tr_data;
            
            % Reshape mask to apply to flim data
            n_mask = sum(roi_mask(:));
            rep_mask = reshape(roi_mask,[1 1 size(roi_mask,1) size(roi_mask,2)]);
            rep_mask = repmat(rep_mask,[n_tr_t obj.n_chan 1 1]);
            
            % Recover selected data
            data = data(rep_mask);
            data = reshape(data,[n_tr_t obj.n_chan n_mask]);
            
            %data = data;
            
            %d = reshape(data,[size(data,1) size(data,3)]); 
            %[mul off] = determine_photon_stats(d);
            %disp([mul off]);
        end
        
        
        function data = define_tvb_profile(obj,roi_mask,dataset)
            % Get data
            obj.switch_active_dataset(dataset);
            data = double(obj.cur_data) - obj.background;
            
            % Reshape mask to apply to flim data
            n_mask = sum(roi_mask(:));
            rep_mask = reshape(roi_mask,[1 1 size(roi_mask,1) size(roi_mask,2)]);
            rep_mask = repmat(rep_mask,[obj.n_t obj.n_chan 1 1]);
            
            % Recover selected data
            data = data(rep_mask);
            data = reshape(data,[obj.n_t obj.n_chan n_mask]);
            
            obj.tvb_profile = nanmean(data,3);
            
            obj.compute_tr_tvb_profile();
            notify(obj,'data_updated');    
        end
        
        function idx = get_intensity_idx(obj,sel)
            
            if obj.loaded(sel)
                idx = sum(obj.loaded(1:sel));
            else
                obj.load_selected_files(sel);
                idx = 1;
            end
            
        end
        
        function sel_intensity = selected_intensity(obj,sel,apply_mask)
           
            if nargin < 3
                apply_mask = true;
            end
            
            obj.switch_active_dataset(sel);
            sel_intensity = obj.intensity;            
            if apply_mask
                sel_intensity(obj.mask==0) = 0;
                if ~isempty(obj.seg_mask)
                    sel_intensity(obj.seg_mask(:,:,sel)==0) = 0;
                end
            end
        end
        
        function [perp_shift] = shifted_perp(obj,perp)
           
            perp_shift = interp1(obj.tr_t,perp,obj.tr_t-obj.irf_perp_shift)';
            
        end
        
        function [g,err] = get_g_factor_roi(obj,roi_mask,dataset)
            
            if obj.polarisation_resolved
                data = obj.get_roi(roi_mask,dataset);
                data = nansum(data,3);
                
                para = data(:,1);
                perp = data(:,2);
                
                
                g = para./perp;
                err = g .* sqrt( 1./para + 1./perp );                
            else
                g = [];
                err = [];
            end
            
        end
        
        function [magic,magic_irf] = get_magic_angle_roi(obj,roi_mask,dataset)
            
            if obj.polarisation_resolved
                data = obj.get_roi(roi_mask,dataset);
                
                if ndims(data) == 3
                    n_px = size(data,3);
                else
                    n_px = 1;
                end
                                
                data = nansum(data,3);
                
                para = data(:,1);
                perp = data(:,2);
                perp_shift = obj.shifted_perp(perp) * obj.g_factor;
                magic_irf = obj.tr_irf(:,1);

                parac = conv(para,obj.tr_irf(:,2));
                perpc = conv(perp,obj.tr_irf(:,1));
                magic_irf = conv(obj.tr_irf(:,1),obj.tr_irf(:,2));
                
                [~,n] = max(obj.tr_irf(:,1));
                
                magic = (parac+2*perpc);
                
                magic = magic((1:size(data,1))+n,:);
                magic_irf = magic_irf((1:size(obj.tr_irf))+n);
                
            else
                magic = [];
                magic_irf = [];
            end
            
        end

        function anis = get_anisotropy_roi(obj,roi_mask,dataset)
            
            if obj.polarisation_resolved
                data = obj.get_roi(roi_mask,dataset);
                data = nansum(data,3);
                
                para = data(:,1);
                perp = data(:,2);
                perp_shift = obj.shifted_perp(perp) * obj.g_factor;
                
                anis = (para-perp_shift)./(para+2*perp_shift);
                
                parac = conv(para,obj.tr_irf(:,2));
                perpc = conv(perp,obj.tr_irf(:,1));
                [~,n] = max(obj.tr_irf(:,1));
                anis = (parac-perpc)./(parac+2*perpc);
                anis = anis((1:size(data,1))+n,:);
                
                anis = anis;
                
                
                
            else
                anis = [];
            end
            
        end

        
        function estimate_g_factor(obj)
            
            [g std] = obj.get_g_factor_roi(1,1);
            
            gf = g(std<0.2);
            
            [~, peak] = max(gf);
            grad = gradient(gf);
            
            gauss_fit = gmdistribution.fit(gf,2,'Replicates',10);
            [~,idx] = max(gauss_fit.PComponents);
            obj.g_factor = gauss_fit.mu(idx);
            
            

        end
        
        
        %===============================================================

        function bg = get.background(obj)
            %> Retrieve background in same shape as flim data
            
            switch obj.background_type
                case 0
                    bg = 0;
                case 1
                    bg = obj.background_value;
                case 2
                    % Check if we have a background image of the correct size
                    s = size(obj.background_image);
                    if ~isempty(obj.background_image) && s(1) == obj.height && s(2) == obj.width
                        bg = obj.background_image;
                        bg = reshape(bg,[1 1 s]);
                        bg = repmat(bg,[obj.n_t obj.n_chan 1 1]);
                    else
                        warning('GlobalAnalysis:IncompatibleBackground','Background image is not the same size as the data');
                        bg = 0;
                    end
                otherwise
                    bg = 0;
            end
           
        end
        
        
        %===============================================================
       
        function set.data_size(obj,data_size)
            s = length(data_size);
            if s == 3
                data_size = [data_size(1) 1 data_size(2:3)];
            end
            obj.data_size = [data_size(:) ; ones(5-s,1)];
        end
        
        function set.polarisation_resolved(obj,polarisation_resolved)
           
            obj.polarisation_resolved = polarisation_resolved;
            
            if polarisation_resolved
                obj.n_chan = 2;
            else
                obj.n_chan = 1;
            end
            
        end
        
        function set.suspend_transformation(obj,suspend_transformation)
           
            obj.suspend_transformation = suspend_transformation;
            
            if ~suspend_transformation
                obj.compute_tr_data();
            end
            
        end
        
        function set.seg_mask(obj,seg_mask)
            %> Set data segmentation mask 
            
            % Check segmentation mask is the right size
            if ~isempty(seg_mask)
                obj.seg_mask = seg_mask;
                obj.compute_mask;
                notify(obj,'masking_updated');
            else
                obj.seg_mask = [];
                obj.compute_mask;
                notify(obj,'masking_updated');
            end
        end
        
        function set.binning(obj,binning)
            obj.binning = binning;
            obj.compute_tr_data;
        end
        
        function set.downsampling(obj,downsampling)
            obj.downsampling = downsampling;
            obj.compute_tr_data;
        end
        
        function set.thresh_min(obj,thresh_min)
            obj.thresh_min = thresh_min;
            obj.compute_mask;
            notify(obj,'masking_updated');
        end
        
        function set.gate_max(obj,gate_max)
           obj.gate_max = gate_max;
           obj.compute_mask;
           notify(obj,'masking_updated');
        end
        
        function set.t_min(obj,t_min)
           obj.t_min = t_min;
           obj.compute_tr_data;
        end
        
        function set.t_max(obj,t_max)
            obj.t_max = t_max;
            obj.compute_tr_data;
        end
        
        function set.t_irf_max(obj,t_irf_max)
            obj.t_irf_max = t_irf_max;
            obj.compute_tr_irf();
            notify(obj,'data_updated');
        end
        
        function set.t_irf_min(obj,t_irf_min)
            obj.t_irf_min = t_irf_min;
            obj.compute_tr_irf();
            notify(obj,'data_updated');
        end
        
        function set.irf_background(obj,irf_background)
            obj.irf_background = irf_background;
            obj.compute_tr_irf;
            notify(obj,'data_updated');
        end
        
        function set.background_type(obj,background_type)
            obj.background_type = background_type;
            obj.compute_tr_data();
        end
        
        function set.background_value(obj,background_value)
            obj.background_value = background_value;
            obj.compute_tr_data();
        end
        
        function set.g_factor(obj,g_factor)
            obj.g_factor = g_factor;
            obj.compute_tr_irf();
            notify(obj,'data_updated');
        end
        
        function set.t0(obj,t0)
            obj.t0 = t0;
            obj.compute_tr_irf();
            notify(obj,'data_updated');
        end
        
        function set.afterpulsing_correction(obj,afterpulsing_correction)
            obj.afterpulsing_correction = afterpulsing_correction;
            obj.compute_tr_irf();
            notify(obj,'data_updated');
        end
        
        
        %===============================================================
        
        function width = get.width(obj)
            if length(obj.data_size) > 3
                width = obj.data_size(4);
            else
                width = 1;
            end
        end
        
        function height = get.height(obj)
            if length(obj.data_size) > 2
                height = obj.data_size(3);
            else
                height = 1;
            end
        end
        
        function n_datasets = get.n_datasets(obj)
            n_datasets = obj.num_datasets;
        end
                
        function n_t = get.n_t(obj)
            n_t = obj.data_size(1);
        end     
                
        function n_masked = get.n_masked(obj)
            n_masked = sum(obj.mask(:));
        end
        
        
        %===============================================================
        
        function set_delta_irf(obj)
           obj.t_irf = [-0.1; 0; 0.1];
           obj.irf = [0; 1; 0];
           
           obj.compute_tr_irf();
           notify(obj,'data_updated');
        end
        
        function set_gaussian_irf(obj,width)
            hw = width / 2;
            ext = 2;
            n_irf = 100;
            obj.t_irf = (1:n_irf) * (hw * ext) / n_irf - (hw * 0.5 * ext);
            obj.irf = 1/(hw*sqrt(2*pi)) * exp(-0.5*(obj.t_irf/hw).^2);  
            
            obj.compute_tr_irf();
            
            notify(obj,'data_updated');
        end
        
        function set_rectangular_irf(obj,width)
            n_irf = 100;
            
            obj.t_irf = (1:n_irf) * width/n_irf;
            obj.irf = ones(size(obj.t_irf));
            
            obj.t_irf = [ min(obj.t_irf)-1 obj.t_irf max(obj.t_irf)+1 ]'; %#ok
            obj.irf = [0 obj.irf 0]';
            
            obj.compute_tr_irf();
            
            notify(obj,'data_updated');
        end

        
        %===============================================================

        function compute_mask(obj)
            %> Compute mask based on thresholds and segmentation mask
            
            if obj.init
                obj.thresh_mask = obj.intensity >= obj.thresh_min & squeeze(max(max(obj.cur_data,[],1),[],2)) < obj.gate_max;
                obj.mask = obj.thresh_mask;

                v = obj.intensity(obj.mask);
                obj.max = max(v);  %#ok
                obj.min = min(v);  %#ok
                
                % If we have a segmentation mask apply it the mask
                if ~isempty(obj.seg_mask)
                    seg = obj.seg_mask(:,:,obj.active);
                    seg(~obj.mask) = 0;
                    obj.mask = seg;
                end
                
            end
        end

        
        function compute_intensity(obj)
            obj.compute_mask();
        end
        
        
        function inten = integrated_intensity(obj,sel)
            
            inten = zeros([obj.height obj.width length(sel)]);

            for i = 1:length(sel)
                obj.switch_active_dataset(sel(i));
                inten(:,:,i) = obj.intensity;
            end

        end
        
        function anis = steady_state_anisotropy(obj,sel)
            
            if obj.polarisation_resolved

                anis = zeros([obj.height obj.width length(sel)]);
                
                g = obj.g_factor;
                
                for i = 1:length(sel)
                    obj.switch_active_dataset(sel(i));
                    in = obj.cur_tr_data;
                    in = nansum(in,1);
                    
                    para = squeeze(in(1,1,:,:));
                    perp = squeeze(in(1,2,:,:));
                    
                    an = (para-g*perp)./(para+2*g*perp);
                    an(obj.mask==0) = NaN;
                    
                    anis(:,:,i) = an;

                end
                
            else
                anis = [];
            end
            
        end
        
        
        %===============================================================
        
        function delete(obj)
           % On object deletion, clear mapped data 
           obj.save_data_settings();
           obj.clear_memory_mapping();
           
        end
        
        
    end
    
end