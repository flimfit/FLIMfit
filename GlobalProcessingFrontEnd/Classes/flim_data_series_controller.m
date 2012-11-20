%> @ingroup UserInterfaceControllers
classdef flim_data_series_controller < handle 
    
    properties(SetObservable = true)
        
        data_series;
        fitting_params_controller;
        window;
        version;
        
        % OMERO
        omero_logon_filename = 'omero_logon.xml';        
        logon;
        client;     
        session;    
        dataset;    
        project;    
        plate; 
        screen;        
        %
        selected_channel; % need to keep this for results uploading to Omero...
        ZCT; % array containing missing OME dimensions Z,C,T (in that order)
        % OMERO           
        
        data_settings_filename = {'data_settings.xml', 'polarisation_data_settings.xml'};
    end
    
    events
        new_dataset;
    end
    
    methods
        
        function obj = flim_data_series_controller(varargin)
            
            handles = args2struct(varargin);
            clear obj.data_series;

            assign_handles(obj,handles);
            
            if isempty(obj.data_series) 
                obj.data_series = flim_data_series();
            end
        end
        
        function file_name = save_settings(obj)
            if isvalid(obj.data_series)
                file_name = obj.data_series.save_data_settings();
            end
        end
        
        function reuse = check_reuse_settings(obj,setting_file_name)
        	reuse = false;
            %{
            if ~isempty(setting_file_name)
                reuse = questdlg('Would you like to reuse data settings from the last dataset? This will keep your IRF and transformation settings','Reuse settings','Yes','No','Yes');
                reuse = strcmp(reuse,'Yes');
            else
                reuse = false;
        	end
            %}
        end
        
        
        function load_data_series(obj,root_path,mode,polarisation_resolved,setting_file_name,selected,channels)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.save_settings();
            
            if nargin < 6
                channels = [];
            end
            
            if nargin < 4
                polarisation_resolved = false;
            end
            
            if nargin < 5
                % if no setting file was specified ask if user want to
                % reuse last settings
                reuse = obj.check_reuse_settings(saved_setting_file_name);
                if ~reuse
                    setting_file_name = [];
                else
                    setting_file_name = saved_setting_file_name;
                end
            end
           
            % load new dataset
            if nargin < 6
                selected = [];
            end
            
            
            obj.data_series = flim_data_series();
            obj.data_series.load_data_series(root_path,mode,polarisation_resolved,setting_file_name,selected,channels);
            
%            obj.fitting_params_controller.set_polarisation_mode(polarisation_resolved);
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[root_path ' (' obj.version ')']);
            end

            notify(obj,'new_dataset');
        end
        
        function load_raw(obj,file,setting_file_name)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.save_settings();
            
            obj.data_series = flim_data_series();
            obj.data_series.load_raw_data(file);
           
            
            if nargin < 4
                % if no setting file was specified ask if user want to
                % reuse last settings
                obj.check_reuse_settings(saved_setting_file_name);
            else
                % if setting file was specified use that
                obj.data_series.load_data_settings(setting_file_name);
            end
                       
            if ~isempty(obj.window)
                set(obj.window,'Name',[file ' (' obj.version ')']);
            end
            
            notify(obj,'new_dataset');
        end
        
        function load_single(obj,file,polarisation_resolved,setting_file_name,channels)
            % save settings from previous dataset if it exists
            saved_setting_file_name = obj.save_settings();
 
            if nargin < 5
                channels = [];
            end
            
            if nargin < 4
                setting_file_name = [];
            end
            
            if nargin < 3
                polarisation_resolved = false;
            end

            % load new dataset
            obj.data_series = flim_data_series();
            obj.data_series.load_single(file,polarisation_resolved,setting_file_name,channels);
            
            %{
            if nargin < 4
                % if no setting file was specified ask if user want to
                % reuse last settings
                obj.check_reuse_settings(saved_setting_file_name);
            else
                % if setting file was specified use that
                obj.data_series.load_data_settings(setting_file_name);
            end
            %}
            
            if ~isempty(obj.window)
                set(obj.window,'Name',[file ' (' obj.version ')']);
            end
                        
            notify(obj,'new_dataset');
        end

        function intensity = selected_intensity(obj,selected,apply_mask)
           
            if nargin == 2
                apply_mask = true;
            end
            
            if obj.data_series.init && selected > 0 && selected <= obj.data_series.n_datasets
                
                intensity = obj.data_series.selected_intensity(selected,apply_mask);
                
            else
                intensity = [];
            end
            
        end
        
        function mask = selected_mask(obj,selected)
           
            if obj.data_series.init && selected > 0 && selected <= obj.data_series.n_datasets
                
                mask = obj.data_series.mask(:,:,selected);
                if ~isempty(obj.data_series.seg_mask)
                    seg_mask = obj.data_series.seg_mask(:,:,selected);
                    mask = mask & seg_mask;
                end
                                
            else
                mask = [];
            end
            
        end
                
        function delete(obj)
        end
        
        %------------------------------------------------------------------
        % OMERO
        %------------------------------------------------------------------
        function channel = fetch_TCSPC(obj, imageDescriptor)
                        
            polarisation_resolved = false;
            
            % load new dataset
            obj.data_series = flim_data_series();            
            %
            image = get_Object_by_Id(obj.session,java.lang.Long(imageDescriptor{2}));
            mdta = get_FLIM_params_from_metadata(obj.session,image.getId(),'metadata.xml');
                        
            if isempty(mdta.n_channels) || mdta.n_channels > 1
                channel = obj.data_series.request_channels(polarisation_resolved);
            else
                channel = 1;
            end;
            %
            if     strcmp(mdta.FLIM_type,'TCSPC')
                obj.data_series.mode = 'TCSPC'; 
            elseif strcmp(mdta.FLIM_type,'Gated')
                obj.data_series.mode = 'widefield';
            else
                obj.data_series.mode = 'TCSPC'; % not annotated sdt
            end
            %
            if ~isempty(mdta.n_channels) && mdta.n_channels==mdta.SizeC && ~strcmp(mdta.modulo,'ModuloAlongC') %if native multi-spectral FLIM
                obj.ZCT = [mdta.SizeZ channel mdta.SizeT]; 
            else
                obj.ZCT = get_ZCT(image,mdta.modulo);
            end
            %
            try
                obj.data_series.fetch_TCSPC(imageDescriptor, polarisation_resolved, channel, obj.ZCT);            
            catch err 
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            
        end
                        
        %------------------------------------------------------------------                
        function OMERO_Set_Dataset(obj,~,~)
            %
            obj.screen = [];
            obj.plate = [];
            %
            [ Dataset Project ] = select_Dataset(obj.session,'Select a Dataset:'); 
            %
            if isempty(Dataset), return, end;
            %
            obj.dataset = Dataset;
            obj.project = Project;
            % 
        end                
        
        %------------------------------------------------------------------                
        function OMERO_Set_Plate(obj,~,~)
            %
            obj.project = [];
            obj.dataset = [];
            %
            [ Plate Screen ] = select_Plate(obj.session,'Select a Plate:'); 
            %
            if isempty(Plate), return, end;
            %
            obj.plate = Plate;
            obj.screen = Screen;
            % 
        end                
                
        %------------------------------------------------------------------        
        function OMERO_Load_FLIM_Data(obj,~,~)
            %
            if ~isempty(obj.plate)                
                image = select_Image(obj.session,obj.plate);                
            elseif ~isempty(obj.dataset)
                image = select_Image(obj.session,obj.dataset);
            else
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return; 
            end;
            %
            if ~isempty(image) 
                try
                    obj.selected_channel = obj.fetch_TCSPC({obj.session, image.getId().getValue()});                                                                                    
                catch err
                    [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                    
                end
            end
            %
        end                          
        
        %------------------------------------------------------------------        
        function OMERO_Load_FLIM_Dataset(obj,~,~)
            %
            if isempty(obj.plate) && isempty(obj.dataset)
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return;                 
            end;
            %
            extension = 'sdt'; % used....
            %
            if ~isempty(obj.plate) 
            %
            z = 0;       
            imageids_unsorted = [];
            str = char(256,256);
                 
                            wellList = obj.session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(obj.plate.getId().getValue())],[]);
                            for j = 0:wellList.size()-1,
                                well = wellList.get(j);
                                wellsSampleList = well.copyWellSamples();
                                well.getId().getValue();
                                for i = 0:wellsSampleList.size()-1,
                                    ws = wellsSampleList.get(i);
                                    ws.getId().getValue();
                                    % pa = ws.getPlateAcquisition();
                                    z = z + 1;
                                    image = ws.getImage();
                                    iid = image.getId().getValue();
                                    idName = num2str(image.getId().getValue());
                                    iName = char(java.lang.String(image.getName().getValue()));
                                    image_name = [ idName ' : ' iName ];
                                    str(z,1:length(image_name)) = image_name;
                                    imageids_unsorted(z) = iid;
                                end
                            end                  
                %
                folder_names_unsorted = cellstr(str);
                %
                folder_names = sort_nat(folder_names_unsorted); % sorted
                [folder_names, ~, obj.data_series.lazy_loading] = dataset_selection(folder_names);   
                %
                num_datasets = length(folder_names);
                %
                image_ids = zeros(1,num_datasets); %sorted
                %
                for m = 1:num_datasets
                    iName_m = folder_names{m};
                    for k = 1:numel(folder_names_unsorted)                       
                        iName_k = folder_names_unsorted{k};
                        if strcmp(iName_m,iName_k)
                            image_ids(1,m) = imageids_unsorted(k);
                            break;
                        end;
                    end 
                end                                
                %
            elseif ~isempty(obj.dataset) 
                %
                imageList = obj.dataset.linkedImageList;
                %       
                if 0==imageList.size()
                    errordlg(['Dataset have no images - please choose Dataset with images'])
                    return;
                end;                                    
                %        
                z = 0;       
                str = char(512,256); % ?????
                for k = 0:imageList.size()-1,                       
                    z = z + 1;                                                       
                    iName = char(java.lang.String(imageList.get(k).getName().getValue()));                                                                
                    A = split('.',iName);
                    if true % strcmp(extension,A(length(A))) 
                        str(z,1:length(iName)) = iName;
                    end;
                 end 
                %
                folder_names = sort_nat(cellstr(str));
                %
                [folder_names, ~, obj.data_series.lazy_loading] = dataset_selection(folder_names);            
                %
                num_datasets = length(folder_names);
                %
                % find corresponding Image ids list...
                image_ids = zeros(1,num_datasets);
                for m = 1:num_datasets
                    iName_m = folder_names{m};
                    for k = 0:imageList.size()-1,                       
                             iName_k = char(java.lang.String(imageList.get(k).getName().getValue()));
                             if strcmp(iName_m,iName_k)
                                image_ids(1,m) = imageList.get(k).getId().getValue();
                                break;
                             end;
                    end 
                end
                %
            end % Dataset...
            %            
            polarisation_resolved = false;            
            % load new dataset
            obj.data_series = flim_data_series();            
            %
            if 0==numel(image_ids), return, end;
            %                       
            image_descriptor{1} = obj.session;
            image_descriptor{2} = image_ids(1);                        
            image = get_Object_by_Id(obj.session,java.lang.Long(image_descriptor{2}));
            %
            mdta= get_FLIM_params_from_metadata(obj.session,image.getId(),'metadata.xml');
            %
            obj.ZCT = get_ZCT(image, mdta.modulo);
            %
            if isempty(mdta.n_channels) || mdta.n_channels > 1
                obj.selected_channel = obj.data_series.request_channels(polarisation_resolved);            
            else
                obj.selected_channel = 1;
            end;
            %
            if     strcmp(mdta.FLIM_type,'TCSPC')
                obj.data_series.mode = 'TCSPC'; 
            elseif strcmp(mdta.FLIM_type,'Gated')
                obj.data_series.mode = 'widefield';
            else
                obj.data_series.mode = 'TCSPC'; % not annotated sdt..
            end
            if ~isempty(mdta.n_channels) && mdta.n_channels==mdta.SizeC && ~strcmp(mdta.modulo,'ModuloAlongC') %if native multi-spectral FLIM
                obj.ZCT = [mdta.SizeZ channel mdta.SizeT]; 
            else
                obj.ZCT = get_ZCT(image,mdta.modulo);
            end
            %                                   
            try
                [delays, data_cube, name] = OMERO_fetch(image_descriptor, obj.selected_channel,obj.ZCT);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end      
            data_size = size(data_cube);
            %
            % if only one channel reshape to include singleton dimension
            if length(data_size) == 3
                data_size = [data_size(1) 1 data_size(2:3)];    
            end
            clear('data_cube');
            %
            obj.data_series.data_size = data_size;
            obj.data_series.num_datasets = num_datasets;       
            %
            %set names
            obj.data_series.names = cell(1,num_datasets);
            for j=1:num_datasets
                % need to remove extension - for sdt...
                string = strrep(folder_names{j},['.' extension],'');
                obj.data_series.names{j} = string;
            end
            %        
            if numel(delays) > 0 % ??
                %
                obj.data_series.file_names = {'file'};
                obj.data_series.channels = 1;
                obj.data_series.metadata = extract_metadata(obj.data_series.names);        
                obj.data_series.polarisation_resolved = polarisation_resolved;
                obj.data_series.t = delays;
                obj.data_series.use_memory_mapping = false;
                obj.data_series.load_multiple_channels = false; % YA
                %
                if obj.data_series.lazy_loading        
                    obj.data_series.load_selected_files_Omero(obj.session,image_ids,1,obj.selected_channel,obj.ZCT);
                else
                    obj.data_series.load_selected_files_Omero(obj.session,image_ids,1:obj.data_series.num_datasets,obj.selected_channel,obj.ZCT);        
                end    
                % ?
                obj.data_series.switch_active_dataset(1);    
                % ?
                %obj.data_series.init_dataset(dataset_indexting_file);                    
                obj.data_series.init_dataset();            
            end
        end            
                
        %------------------------------------------------------------------        
        function OMERO_Load_IRF_annot(obj,~,~)
            %
            if ~isempty(obj.dataset)
                parent = obj.dataset;
            elseif ~isempty(obj.plate)
                parent = obj.plate;
            else
                errordlg('please set Dataset or Plate and load the data before loading IRF'), return;
            end;
            %    
            [str fname] = select_Annotation(obj.session, parent,'Please choose IRF file');
            %
            if isempty(str)
                return;
            end;            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
            %
            if strcmp('sdt',fname(numel(fname)-2:numel(fname)))
                fwrite(fid,typecast(str,'double'),'double');
            else                
                fwrite(fid,str,'*uint8');
            end
            %
            fclose(fid);
            %
            try
                obj.data_series.load_irf(full_temp_file_name);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            %
            %delete(full_temp_file_name); %??
        end            
        
        %------------------------------------------------------------------
        function tempfilename = OMERO_load_imagefile(obj,~,~)    
            %
            tempfilename = [];            
            %
            if isempty(obj.dataset)
                [ Dataset ~ ] = select_Dataset(obj.session,'Select a Dataset:');             
                if isempty(Dataset), return, end;                
            else
                Dataset = obj.dataset;
            end;
            %    
            image = select_Image(obj.session,Dataset);                       
            if isempty(image), return, end;
            %   
            try
                zct = get_ZCT(image,'ModuloAlongC');
                data_cube = get_FLIM_cube( obj.session, image.getId().getValue(), 1, 1,'ModuloAlongC',zct);            
                data = squeeze(data_cube);
                %
                tempfilename = [tempname '.tif'];
                if 2 == numel(size(data))
                    imwrite(data,tempfilename,'tif');           
                else
                   sz = size(data); 
                   nimg = sz(1);
                     for ind = 1:nimg,
                        imwrite( data(:,:,ind),tempfilename,'WriteMode','append');
                     end             
                end
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                 
            end
            %
        end            
        
        %------------------------------------------------------------------
        function OMERO_Export_Fitting_Results(obj,fit_controller,~)
            %
            if ~fit_controller.has_fit
                 errordlg('There are no analysis results - nothing to Export');
                 return;
            end
            %
            % get first parameter image just to get the size
            res = fit_controller.fit_result;
            params = res.fit_param_list();
            n_params = length(params);
            param_array(:,:) = single(res.get_image(1, params{1}));
                sizeY = size(param_array,1);
                sizeX = size(param_array,2);
            %            
            choice = questdlg(['Do you want to Export fitting results as new Dataset or new Plate?'], ' ', ...
                                    'new Dataset' , ...
                                    'new Plate','Cancel','Cancel');              
                                
            clear_dataset_project_after_export = false;
            clear_plate_screen_after_export = false;
            switch choice
                case 'new Dataset',
                    if isempty(obj.dataset)
                        [ dtst prjct ] = select_Dataset(obj.session,'Select Dataset:'); 
                        if isempty(dtst), return, end;
                        obj.dataset = dtst;
                        obj.project = prjct;
                        clear_dataset_project_after_export = true;
                    end
                case 'new Plate', 
                    if isempty(obj.plate)
                        [ plte scrn ] = select_Plate(obj.session,'Select Plate:'); 
                        if isempty(plte), return, end;
                        obj.plate = plte;
                        obj.screen = scrn;
                        clear_plate_screen_after_export = true;
                    end
                case 'Cancel', 
                    return;
            end                        
            
            if ~isempty(obj.dataset)                
                %
                dName = char(java.lang.String(obj.dataset.getName().getValue()));
                pName = char(java.lang.String(obj.project.getName().getValue()));
                name = [ pName ' : ' dName ];
                %
                choice = questdlg(['Do you want to Export current results on ' name ' to OMERO? It might take some time.'], ...
                                        'Export current analysis' , ...
                                        'Export','Cancel','Cancel');              
                switch choice
                    case 'Cancel', return;
                end            
                %
                current_dataset_name = char(java.lang.String(obj.dataset.getName().getValue()));    

                new_dataset_name = [current_dataset_name ' FLIM fitting channel ' num2str(obj.selected_channel) ...
                        ' Z ' num2str(obj.ZCT(1)) ...
                                            ' C ' num2str(obj.ZCT(2)) ...
                                                                ' T ' num2str(obj.ZCT(3)) ' ' ...
                datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];

                description  = ['analysis of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
                newdataset = create_new_Dataset(obj.session,obj.project,new_dataset_name,description);                                                                                                    
                %
                if isempty(newdataset)
                    errordlg('Can not create new Dataset');
                    return;
                end
                %
                hw = waitbar(0, 'Exporting fitting results to Omero, please wait');                 
                for dataset_index = 1:obj.data_series.num_datasets
                    %
                    data = zeros(n_params,sizeX,sizeY);
                        for p = 1:n_params,
                            data(p,:,:) = res.get_image(dataset_index, params{p})';
                        end
                    %                  
                    new_image_description = ' ';

                    new_image_name = char(['FLIM fitting channel ' num2str(obj.selected_channel) ...
                        ' Z ' num2str(obj.ZCT(1)) ...
                                            ' C ' num2str(obj.ZCT(2)) ...
                                                                ' T ' num2str(obj.ZCT(3)) ' ' ...
                    obj.data_series.names{dataset_index}]);

                    imageId = mat2omeroImage(obj.session, data, 'double', new_image_name, new_image_description, res.fit_param_list(),'ModuloAlongC');
                    link = omero.model.DatasetImageLinkI;
                    link.setChild(omero.model.ImageI(imageId, false));
                    link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false));
                    obj.session.getUpdateService().saveAndReturnObject(link); 
                    %   
                    waitbar(dataset_index/obj.data_series.num_datasets, hw);
                    drawnow;                                                                 
                end;
                delete(hw);
                drawnow;                                  
                %
                if clear_dataset_project_after_export
                    obj.dataset = [];
                    obj.project = [];
                end;
                
            else % if isempty(obj.dataset) - work with SPW layout
                 z = 0;       
                 %
                 newplate = [];
                 updateService = obj.session.getUpdateService();        
                 %
                            wellList = obj.session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(obj.plate.getId().getValue())],[]);
                        
                            hw = waitbar(0, 'Exporting fitting results to Omero, please wait');                 
                            %
                            for j = 0:wellList.size()-1,
                                well = wellList.get(j);
                                wellsSampleList = well.copyWellSamples();
                                well.getId().getValue();
                                for i = 0:wellsSampleList.size()-1,
                                    ws = wellsSampleList.get(i);
                                    ws.getId().getValue();
                                    % pa = ws.getPlateAcquisition();
                                    image = ws.getImage();
                                    iId = image.getId().getValue();
                                    imgName = char(java.lang.String(image.getName().getValue()));                                                                        
                                        % compare with what we have in analysis...        
                                        for dataset_index = 1:obj.data_series.num_datasets
                                            str = split(' : ',obj.data_series.names{dataset_index});
                                            imgname = char(str(2));                                        
                                            iid = str2num(str2mat(cellstr(str(1)))); % wtf                                        
                                            if (1==strcmp(imgName,imgname)) && (iid == iId) % put new well into new plate
                                                %
                                                if isempty(newplate) % create new plate                                                    
                                                    current_plate_name = char(java.lang.String(obj.plate.getName().getValue()));    
                                                    newplate_name = [current_plate_name ' FLIM fitting channel ' num2str(obj.selected_channel) ...
                                                    ' Z ' num2str(obj.ZCT(1)) ...
                                                    ' C ' num2str(obj.ZCT(2)) ...
                                                    ' T ' num2str(obj.ZCT(3)) ' ' ...
                                                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                                                        
                                                            newplate = omero.model.PlateI();
                                                            newplate.setName(omero.rtypes.rstring(newplate_name));    
                                                            newplate.setColumnNamingConvention(obj.plate.getColumnNamingConvention());
                                                            newplate.setRowNamingConvention(obj.plate.getRowNamingConvention());                                                                    
                                                            newplate = updateService.saveAndReturnObject(newplate);
                                                            link = omero.model.ScreenPlateLinkI;
                                                            link.setChild(newplate);            
                                                            link.setParent(omero.model.ScreenI(obj.screen.getId().getValue(),false));            
                                                            updateService.saveObject(link);                                                     
                                                end % create new plate
                                                %                   
                                                    newwell = omero.model.WellI;    
                                                    newwell.setRow(well.getRow());
                                                    newwell.setColumn(well.getColumn());
                                                    newwell.setPlate( omero.model.PlateI(newplate.getId().getValue(),false) );
                                                    newwell = updateService.saveAndReturnObject(newwell);        
                                                    newws = omero.model.WellSampleI();
                                                        %results image
                                                            data = zeros(n_params,sizeX,sizeY);
                                                                for p = 1:n_params,
                                                                    data(p,:,:) = res.get_image(dataset_index, params{p})';
                                                                end                                                                                  
                                                            new_image_description = ' ';
                                                            new_image_name = char(['FLIM fitting channel ' num2str(obj.selected_channel) ...
                                                            ' Z ' num2str(obj.ZCT(1)) ...
                                                            ' C ' num2str(obj.ZCT(2)) ...
                                                            ' T ' num2str(obj.ZCT(3)) ' ' ...
                                                            obj.data_series.names{dataset_index}]);
                                                            new_imageId = mat2omeroImage(obj.session, data, 'double', new_image_name, new_image_description, res.fit_param_list(),'ModuloAlongC');
                                                        %results image
                                                    newws.setImage( omero.model.ImageI(new_imageId,false) );
                                                    newws.setWell( newwell );        
                                                    newwell.addWellSample(newws);
                                                    newws = updateService.saveAndReturnObject(newws);                                                                                                                                               
                                                    z = z + 1; % param image count
                                                    waitbar(z/obj.data_series.num_datasets, hw);
                                            end % put new well into new plate                                       
                                        end                                                                        
                                end
                            end
                            delete(hw);
                            drawnow;                                                              
                %        
                if clear_plate_screen_after_export
                    obj.plate = [];
                    obj.acreen = [];
                end;
                
            end
                %
                % attach fitting options to results - including irf etc. ?
                %            
        end            

        %------------------------------------------------------------------        
        function OMERO_Export_Fitting_Settings(obj,fitting_params_controller,~)
            %
            choice = questdlg('Do you want to Export fitting settings to Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object ~ ] = select_Dataset(obj.session,'Select Dataset:'); 
                case 'Plate', 
                    [ object ~ ] = select_Plate(obj.session,'Select Plate:'); 
                case 'Cancel', 
                    return;
            end                        
            %                        
            fname = [tempdir 'fitting settings '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
            fitting_params_controller.save_fitting_params(fname);         
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            ret = add_Annotation(obj.session, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            fname, ...
                            description, ...
                            namespace);               
        end            
        
        %------------------------------------------------------------------
        function OMERO_Import_Fitting_Settings(obj,fitting_params_controller,~)
            %
             if ~isempty(obj.dataset) parent = obj.dataset;
                elseif ~isempty(obj.plate) parent = obj.plate;
             else
                errordlg('please set a Dataset or a Plate'), return;
             end;            
            
            [str fname] = select_Annotation(obj.session, parent,'Please choose settings file');
            %
            if isempty(str)
                return;
            end;
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
                fwrite(fid,str,'*uint8');
            fclose(fid);
            %
            try
                fitting_params_controller.load_fitting_params(full_temp_file_name); 
                delete(full_temp_file_name); 
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end;
        end            
                
        %------------------------------------------------------------------                
        function Omero_logon(obj,~)        
            %
            if exist(obj.omero_logon_filename,'file') 
                [ settings ~ ] = xml_read (obj.omero_logon_filename);    
                obj.logon = settings.logon;
            else
                obj.logon = OMERO_logon();
            end
            %
            obj.client = loadOmero(obj.logon{1});
            try 
                obj.session = obj.client.createSession(obj.logon{2},obj.logon{3});
            catch err
                obj.client = [];
                obj.session = [];
                [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                
            end                        
        end
                
       %------------------------------------------------------------------
       % OMERO
       %------------------------------------------------------------------                                        
        
    end
end