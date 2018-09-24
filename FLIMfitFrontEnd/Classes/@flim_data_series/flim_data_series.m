classdef flim_data_series < handle & h5_serializer
    
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

   
    properties
        mode;
                                      
        tvb_profile = 0;
        tvb_I_image;
          
        irf instrument_response_function;
        
        subtract_background = false;
        
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
                
        counts_per_photon = 1;

        polarisation Polarisation = Polarisation.Unpolarised;
        
        background_type = 0;
        background_value = 0;
        
        rep_rate = nan;
        
        background_image = 0;
        
        use_t_calibration = false;
        cal_t_nominal = 0:10:20e3;
        cal_t_meas = 0:10:20e3;
        cal_dt = 10;        
    end
    
    properties(Dependent)
        width;
        height;
        n_masked;
               
        background;
        
        num_datasets; % This property is for backwards compatability only; do not use in new code
       
        im_size;
        n_t;
    end
    
    properties(SetObservable,Transient)
        suspend_transformation = false;
        n_chan = 1;
        data_size;
        data_type = 'single';
        use;
        
        use_smoothing = false;
    end
        
    properties(SetObservable,Dependent)
       
    end
    
    properties(Transient)
        
        datasetId = -1;   %Set invalid OMERO dataset/plate Id as default
        plateId = -1;
        
        polarisation_resolved = false;

        
        acceptor;
        intensity_normalisation;
        root_path;
        
        t;   
        t_int;
        n_datasets;
        
        names;
        metadata;

        seg_mask = [];
        multid_mask = [];
                
        all_Z_volume_loading = false;
        batch_mode = false;
        
        reader_settings;
    end
    
    properties(Transient,Hidden)
        % Properties that won't be saved to a data_settings_file or to 
        % a project file
        loaded_from_OMERO = false;
        
        header_text = ' ';  % text to be displayed on top bar in GUI
        
        raw = false;
        hdf5 = false;
        
        use_memory_mapping = true;
        
         % semaphore replaces load_multiple_channels. 
         % 0 ==1 plane per image 1,2 or == multiple Z,C or T respectively
        load_multiple_planes = 0;      
        
        tr_data_series_mem = single([]);
        data_series_mem = single([]);
        
            
        mapfile_name;
        memmap;
        mapfile_offset = 0;
                
        cur_data;
        cur_tr_data;
        
        cur_smoothed = 0;
                
        
        intensity = [];
        
        mask = [];
        thresh_mask = [];
                
        tr_t_all;
        tr_t_int;
        
        t_skip;
        
        tr_t;
        
        tr_tvb_profile;
        
        tr_data_size;
        
        init = false;
                
        use_popup = true;  
        lazy_loading = false;
        
        file_names;
        channels;
        imageSeries = -1;
        
        loaded = [];
        load_time = [];
        
        active = 1;
        
        ZCT = []; % cell array containing missing OME dimensions Z,C,T (in that order)  
        modulo = [];
        bfOmeMeta = [];
        bfReader = [];
        
        txtInfoRead = [];
        
        multid_filters_file;
        
        lh;
        
    end
    
    events
        data_updated;
        masking_updated;
        selection_updated;
    end
    
    methods(Static)
        
        data = smooth_flim_data(data,extent,mode)
       
             
        function data = ensure_correct_dimensionality(data)
            %> Ensure that data has singleton dimension for polarisation
            s = size(data);
            if length(s) == 3
                data = reshape(data,[s(1) 1 s(2) s(3)]);
            end
        end
        
    end
    
    methods
        
        
        %===============================================================

        function obj = flim_data_series()
            
            obj.use_memory_mapping = true;
            
            del_files = dir([tempdir 'GPTEMP*']);
            
            warning('off','MATLAB:DELETE:Permission');
            
            for i=1:length(del_files)
                try
                   delete([tempdir del_files(i).name]); 
                catch e %#ok
                end
            end
            
            warning('on','MATLAB:DELETE:Permission');
            
            % set up a temporary file to save filters
            obj.multid_filters_file = tempname;
            
            prof = get_profile();
            obj.rep_rate = prof.Data.Default_Rep_Rate;

            obj.irf = instrument_response_function();            
            obj.lh = addlistener(obj.irf,'updated',@(src,evt) obj.n(src,evt));
            
        end
        
        function n(obj,src,evt)
            try
                notify(obj,'data_updated')
            catch e
                disp(e)
            end
                
        end
        
        function post_serialize(obj)
            
            obj.suspend_transformation = true;
                        
            datatype = class(obj.cur_data);
            
            sz = obj.data_size(:)';
            
            ch_sz = sz;
            sz(end) = obj.n_datasets;
            
            path = '/flim_data/';
                        
            try
                h5create(obj.file,path,sz,'Datatype',datatype,'ChunkSize',ch_sz);
            catch err
                if ~strcmp(err.identifier,'MATLAB:imagesci:h5create:datasetAlreadyExists')
                    throw(err);
                end
            end
            
            for j=1:obj.n_datasets

                obj.switch_active_dataset(j);

                h5write(obj.file,path,obj.cur_data,[1 1 1 1 j],ch_sz,ones(size(sz)));
                
            end
            
            
            obj.suspend_transformation = false;
            
        end
        
        function post_deserialize(obj)
            
            obj.hdf5 = true;
            
        end
        
        %===============================================================
        
        function load_data_settings(obj,file)
            %> Load data setting file 
            obj.suspend_transformation = true;
            obj.marshal_object(file);
            notify(obj,'masking_updated');
            obj.suspend_transformation = false;
            
        end
        
        function file = save_data_settings(obj,file)
            %> Save data setting file
            if nargin < 2
                file = [];
            end
            if obj.init
                if isempty(file) && ~obj.batch_mode % i.e. not batch
                    title = 'Save Settings?';
                    choice = questdlg('Would you like to save the current data settings?', title ,'Yes','No','No');
                    if strcmp(choice,'Yes')
                        pol_idx = obj.polarisation_resolved + 1;
                        file = [obj.root_path obj.data_settings_filename{pol_idx}];     
                    end
                end
                
                if ~isempty(file)
                    serialise_object(obj,file);
                end
                
                
            end
        end
        
        function load_t_calibriation(obj,file)
           
            data = csvread(file,2,0);
            obj.use_t_calibration = true;
            obj.cal_t_nominal = data(:,1);
            obj.cal_t_meas = data(:,2);
            
            obj.compute_tr_data();
            notify(obj,'data_updated');  
            
        end
        
        function reload_data(obj)
            l = 1:obj.n_datasets;
            obj.loaded(:) = false;
            obj.load_selected_files(l);
        end
        
        function export_acceptor_images(obj,file)
            
            SaveFPTiffStack(file,obj.acceptor,obj.names,'Acceptor');
            
        end
        
        %===============================================================
        
        function [data,irf] = get_roi(obj,roi_mask,dataset)
            %> Return an array of data points both in internal mask
            %> and roi_mask from dataset selected
            
            obj.switch_active_dataset(dataset);
                        
            idx = obj.get_intensity_idx(dataset);
            
            % Get mask from thresholding
            m = (obj.mask > 0);
            
            % Combine with segmentation mask, if it exists
            if ~isempty(obj.seg_mask)
               m = m & obj.seg_mask(:,:,idx) > 0; 
            end
            if ~isempty(obj.multid_mask)
               m = m & obj.multid_mask(:,:,idx);
            end
            
            % Then roi_mask
            if ~isempty(roi_mask)
                roi_mask = roi_mask & m;
            else
                roi_mask = m;
            end
                        
            % Get data

            data = obj.cur_tr_data;
            
            data = data(:,:,roi_mask);

            % TODO : move this to IRF
            if obj.irf.has_image_irf
                irf = obj.irf.tr_image_irf(:,:,roi_mask);
                irf = mean(irf,3);
            elseif ~isempty(obj.irf.t0_image)
                offset = mean(obj.irf.t0_image(roi_mask));
                irf = interp1(obj.irf.tr_t_irf,obj.irf.tr_irf,obj.irf.tr_t_irf+offset,'pchip','extrap');
            else
                irf = obj.irf.tr_irf;
            end
            
            
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
                if ~isempty(obj.multid_mask)
                    sel_intensity(~obj.multid_mask(:,:,sel)) = 0;
                end
            end
        end
        
        %function [perp_shift] = shifted_perp(obj,perp)           
        %    perp_shift = interp1(obj.tr_t,perp,obj.tr_t-obj.irf_perp_shift)';
        %end
        
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
                                                
                data = nanmean(data,3);
                
                para = data(:,1);
                perp = data(:,2);
                %perp_shift = obj.shifted_perp(perp) * obj.g_factor;
                %magic_irf = obj.irf.tr_irf(:,1);

                parac = conv(para,obj.irf.tr_irf(:,2));
                perpc = conv(perp,obj.irf.tr_irf(:,1));
                magic_irf = conv(obj.irf.tr_irf(:,1),obj.irf.tr_irf(:,2));
                
                [~,n] = max(obj.irf.tr_irf(:,1));
                
                magic = (parac+2*perpc);
                
                magic = magic((1:size(data,1))+n,:);
                magic_irf = magic_irf((1:size(obj.irf.tr_irf))+n);
                
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
                
                %perp_shift = obj.shifted_perp(perp) * obj.g_factor;
                %anis = (para-perp_shift)./(para+2*perp_shift);
                
                parac = conv(para,obj.irf.tr_irf(:,2));
                perpc = conv(perp,obj.irf.tr_irf(:,1));
                [~,n] = max(obj.irf.tr_irf(:,1));
                anis = (parac-perpc)./(parac+2*perpc);
                anis = anis((1:size(data,1))+n,:);                
                
            else
                anis = [];
            end
            
        end

        
        function estimate_g_factor(obj)
            
            [g, std] = obj.get_g_factor_roi(1,1);
            gf = g(std<0.2);
                        
            gauss_fit = gmdistribution.fit(gf,2,'Replicates',10);
            [~,idx] = max(gauss_fit.PComponents);
            obj.g_factor = gauss_fit.mu(idx);
        end
        
        
        %===============================================================

        function bg = get.background(obj)
            %> Retrieve background in same shape as flim data
            
            % Check that the background size is correct if we have an image
            s = size(obj.background_image);
            if obj.background_type == 2 && ...
                      ~(~isempty(obj.background_image) && s(1) == obj.height && s(2) == obj.width)
                obj.background_type = 0;
            end
            
            switch obj.background_type
                case 0
                    bg = 0;
                case 1
                    bg = obj.background_value;
                case 2
                    obj.background_image = squeeze(obj.background_image);
                    bg = obj.background_image;
                    bg = reshape(bg,[1 1 s]);
                    bg = repmat(bg,[obj.n_t obj.n_chan 1 1]);
                case 3
                    if ~isempty(obj.tvb_I_image)
                        bg = reshape(obj.tvb_I_image,[1 1 obj.height obj.width]);
                        % replace genops!
                        %bg = bg .* obj.tvb_profile + obj.background_value;
                        bg = bsxfun(@times,bg,obj.tvb_profile) + obj.background_value;
                    else
                        bg = 0;
                    end
                otherwise
                    bg = 0;
            end
           
        end
        
        
        %===============================================================
       
        function set.data_size(obj,data_size)
            s = length(data_size);
            obj.data_size = [data_size(:); ones(5-s,1)];
        end
                
        function set.suspend_transformation(obj,suspend_transformation)
           
            obj.suspend_transformation = suspend_transformation;
            
            if ~suspend_transformation
                obj.compute_tr_data();
            end
            
        end
        
        function set.seg_mask(obj,seg_mask)
            if ~isempty(seg_mask)
               obj.seg_mask = seg_mask;
            else
               obj.seg_mask = [];
            end
            obj.compute_mask;
            notify(obj,'masking_updated');
        end
        
        function set.multid_mask(obj,multid_mask)
            if ~isempty(multid_mask)
                obj.multid_mask = multid_mask;
            else
                obj.multid_mask = [];
            end
             obj.compute_mask;
             notify(obj,'masking_updated');
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
                
        function set.background_type(obj,background_type)
            obj.background_type = background_type;
            obj.compute_tr_data();
        end
        
        function set.background_value(obj,background_value)
            obj.background_value = background_value;
            obj.compute_tr_data();
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
                
        function num_datasets = get.num_datasets(obj)
            num_datasets = obj.n_datasets;
        end
        
        function n_t = get.n_t(obj)
            n_t = obj.data_size(1);
        end     
                
        function n_masked = get.n_masked(obj)
            n_masked = sum(obj.mask(:));
        end
        
        %===============================================================

        function compute_mask(obj)
            %> Compute mask based on thresholds and segmentation mask
            
            if obj.init
                
                max_gate = (max(max(obj.cur_data,[],1),[],2));
                max_gate = reshape(max_gate,obj.data_size(3:4)');
                
                obj.thresh_mask = obj.intensity >= obj.thresh_min & max_gate < obj.gate_max;
                obj.mask = obj.thresh_mask;
                
                % If we have a segmentation mask apply it the mask
                if ~isempty(obj.seg_mask)
                    seg = obj.seg_mask(:,:,obj.active);
                    seg(~obj.mask) = 0;
                    obj.mask = seg;
                end
                
                if ~isempty(obj.multid_mask)
                    seg = obj.multid_mask(:,:,obj.active);
                    obj.mask(~seg) = 0;
                end
                
            end
        end

        
        function compute_intensity(obj)
            obj.compute_mask();
        end
        
        
        function inten = integrated_intensity(obj,sel)
            
            inten = zeros([obj.height obj.width length(sel)]);

            for i = 1:length(sel)
                obj.switch_active_dataset(sel(i),true);
                inten(:,:,i) = obj.intensity;
            end

        end
        
        function anis = steady_state_anisotropy(obj,sel)
            
            if obj.polarisation_resolved

                anis = zeros([obj.height obj.width length(sel)]);
                
                g = obj.g_factor;
                
                for i = 1:length(sel)
                    obj.switch_active_dataset(sel(i),true);
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
        
        
        function import_exclusion_list(obj,file)

            f = fopen(file);
            
            
            tline = fgetl(f);
            
            exclude = [];
            if strcmp(tline,'FOV') && isfield(obj.metadata,tline)
                while ischar(tline)
                    tline = fgetl(f);
                    exclude(end+1) = str2double(tline); %#ok
                end
            else
                warning('Only FOV exclusion currently supported');
                return
            end    
            fclose(f);
            
            FOV = obj.metadata.FOV;
            FOV = cell2mat(FOV');
                        
            obj.use = obj.use & ~ismember(FOV,exclude); 
            
        end
        
        function export_exclusion_list(obj,file)

            if isfield(obj.metadata,'FOV')
                exclude = obj.metadata.FOV;
                exclude = exclude(~obj.use);
                
                f = fopen(file,'w');
                
                fprintf(f,'FOV\r\n');
                
                for i=1:length(exclude)
                    fprintf(f, '%d\r\n', exclude{i});
                end
                    
                fclose(f);
                
            else
                warning('No FOV metadata, cannot export exclusion list'); 
            end



        end
        
        function clear(obj)
            if ~isempty(obj.intensity)
                % clear intensity display
                obj.intensity(:) = 0;
                notify(obj,'data_updated');
                obj.cleanup();
            end
        end
            
        
        %===============================================================
        
        function cleanup(obj)
        
           if exist(obj.multid_filters_file,'file')
              delete(obj.multid_filters_file);
           end
            
           obj.save_data_settings();
           % close any bioformats readers saved in class
           r=obj.bfReader;
           if ~isempty(r)
               r.close();
           end
           
        end
        
        function delete(obj)
           obj.cleanup();
           
           % On object deletion, clear mapped data 
           obj.clear_memory_mapping();
        end
        
        
    end
    
end