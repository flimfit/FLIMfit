%> @ingroup UserInterfaceControllers
classdef flim_omero_data_manager < handle 
    
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

   
    
    properties(SetObservable = true)
        
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
        userid;       

    end
        
    methods
        
        function obj = flim_omero_data_manager(varargin)            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            
        end
                                        
        function delete(obj)
        end
                
        %------------------------------------------------------------------                        
        function channel = get_single_channel_FLIM_FOV(obj,image,data_series)
        % data_series MUST BE initiated BEFORE THE CALL OF THIS FUNCTION                                    
            polarisation_resolved = false;
            %
            channel = [];
            %
            mdta = get_FLIM_params_from_metadata(obj.session,image);
            if isempty(mdta) || isempty(mdta.delays)
                errordlg('can not load: data have no FLIM specification');
                return;
            end
           
            delays = mdta.delays;
           
            data_series.ZCT = get_ZCT(image, mdta.modulo, length(delays) );
            
            channel = data_series.ZCT{2};       % not sure why we need this?
            
            data_series.verbose = true;     % loading a single image            
            
            try
                [data_cube, name] = data_series.OMERO_fetch(image, data_series.ZCT, mdta);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end      
            data_size = size(data_cube);
            
            
            data_series.mode = mdta.FLIM_type;
            
            
            if ~isempty(obj.dataset)
                data_series.names{1} = name;            
            else % SPW image - treated differently at results import
                idStr = num2str(image.getId().getValue());
                data_series.names{1} = [ idStr ' : ' name ];                
            end;                
            %
            data_series.data_size = [ data_size 1];
            data_series.n_datasets = 1;  
            data_series.file_names = {'file'};                
            data_series.metadata = extract_metadata(data_series.names);
            data_series.polarisation_resolved = polarisation_resolved;
            data_series.t = delays;
            data_series.use_memory_mapping = false;
            
            data_series.data_series_mem = single(data_cube);
            
            data_series.tr_data_series_mem = single(data_cube); 
             
    
            data_series.load_multiple_channels = false;
            data_series.loaded = ones([1 data_series.n_datasets]);
            data_series.switch_active_dataset(1);    
            data_series.init_dataset();                        
        end
                                
        %------------------------------------------------------------------                
        function infostring = Set_Dataset(obj,~,~)
            %
            infostring = [];            
            obj.screen = [];
            obj.plate = [];
            %
            [ Dataset, Project ] = select_Dataset(obj.session,obj.userid,'Select a Dataset:'); 
            %
            if isempty(Dataset), return, end;
            %
            obj.dataset = Dataset;
            obj.project = Project;
            %            
            if ~isempty(obj.project)
                pName = char(java.lang.String(obj.project.getName().getValue()));
                pIdName = num2str(obj.project.getId().getValue());
            else
                pName = 'NO PROJECT!';
                pIdName = 'XXXX';
            end;
            dName = char(java.lang.String(obj.dataset.getName().getValue()));                    
            dIdName = num2str(obj.dataset.getId().getValue());                       
            infostring = [ 'Dataset "' dName '" [' dIdName '] @ Project "' pName '" [' pIdName ']' ];
            %
        end                
        
        %------------------------------------------------------------------                
        function infostring = Set_Plate(obj,~,~)
            %
            infostring = [];
            obj.project = [];
            obj.dataset = [];
            %
            [ Plate, Screen ] = select_Plate(obj.session,obj.userid,'Select a Plate:'); 
            %
            if isempty(Plate), return, end;
            %
            obj.plate = Plate;
            obj.screen = Screen;
            % 
            sName = char(java.lang.String(obj.screen.getName().getValue()));
            sIdName = num2str(obj.screen.getId().getValue());
            ptName = char(java.lang.String(obj.plate.getName().getValue()));                    
            ptIdName = num2str(obj.plate.getId().getValue());                       
            infostring = [ 'Plate "' ptName '" [' ptIdName '] @ Screen "' sName '" [' sIdName ']' ];
            %            
        end                
                
        %------------------------------------------------------------------        
        function Load_FLIM_Data(obj,data_series,~)
            %
            if ~isempty(obj.plate)                
                image = select_Image(obj.session,obj.userid,obj.plate);                
            elseif ~isempty(obj.dataset)
                image = select_Image(obj.session,obj.userid,obj.dataset);
            else
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return; 
            end;
            %
            data_series.image_ids = [];
            %
            if ~isempty(image) 
                try
                    obj.selected_channel = obj.get_single_channel_FLIM_FOV(image,data_series);
                    data_series.image_ids(1) = image.getId.getValue;
                catch err
                    [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                    
                end
            end
            %
        end                          
                               
        %------------------------------------------------------------------                        
        function channel = get_single_channel_IRF_FOV(obj,image,data_series, load_as_image)
        % data_series MUST BE initiated BEFORE THE CALL OF THIS FUNCTION  
        
            if nargin < 4
                load_as_image = false;
            end
            
            mdta = get_FLIM_params_from_metadata(obj.session,image);
            if isempty(mdta) || isempty(mdta.delays)
                channel = [];
                errordlg('can not load: data have no FLIM specification');
                return;
            end
            
            t_irf = mdta.delays;
            
           
            data_series.ZCT = get_ZCT(image,mdta.modulo, length(t_irf));
            
            channel = data_series.ZCT{2};       % Don't think we need to return this!
           
            try
                [irf_image_data, ~] = data_series.OMERO_fetch(image, data_series.ZCT, mdta);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end      
                   
            irf_image_data = double(irf_image_data);
    
            % Sum over pixels
            s = size(irf_image_data);
            if length(s) == 3
                irf = reshape(irf_image_data,[s(1) s(2)*s(3)]);
                irf = mean(irf,2);
            elseif length(s) == 4
                irf = reshape(irf_image_data,[s(1) s(2) s(3)*s(4)]);
                irf = mean(irf,3);
            else
                irf = irf_image_data;
            end
    
            % export may be in ns not ps.
            if max(t_irf) < 300
                t_irf = t_irf * 1000; 
            end
            
             if load_as_image
                irf_image_data = data_series.smooth_flim_data(irf_image_data,7);
                data_series.image_irf = irf_image_data;
                data_series.has_image_irf = true;
             else
                data_series.has_image_irf = false;
             end

            data_series.t_irf = t_irf(:);
            data_series.irf = irf;
            data_series.irf_name = 'irf';

            data_series.t_irf_min = min(data_series.t_irf);
            data_series.t_irf_max = max(data_series.t_irf);

            data_series.estimate_irf_background();

            data_series.compute_tr_irf();
            data_series.compute_tr_data();

            notify(data_series,'data_updated');
            
        end
                                                      
        %------------------------------------------------------------------        
        function Load_IRF_WF_gated(obj,data_series,~)
            [ Dataset ~ ] = select_Dataset(obj.session,obj.userid,'Select IRF Dataset:');             
            if isempty(Dataset), return, end;            
            load_as_image = false;
            try
                obj.load_irf_from_Dataset(data_series,Dataset,load_as_image);
            catch err
                errordlg('Wrong input: Dataset should contain single-plane images with names encoding delays eg "INT_000750 T_01050.tif" ');
                [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);                
            end
        end            

        %------------------------------------------------------------------                
        function Load_Background_form_Dataset(obj,data_series,~)
            [ Dataset ~ ] = select_Dataset(obj.session,obj.userid,'Select Bckg Dataset:');             
            if isempty(Dataset), return, end;            
            try
                obj.load_background_from_Dataset(data_series,Dataset);                
            catch
                errordlg('Wrong input: Dataset should contain single-plane images of proper size');
                [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);                
            end            
        end
        
        %------------------------------------------------------------------                
        function Load_tvb_from_Image(obj,data_series,~)
            if isempty(obj.dataset)
                [ Dataset, ~ ] = select_Dataset(obj.session,obj.userid,'Select a Dataset:');             
                if isempty(Dataset), return, end;                
            else
                Dataset = obj.dataset;
            end;
            %    
            Image = select_Image(obj.session,obj.userid,Dataset);                       
            if isempty(image), return, end;
            %   
            try
               obj.load_tvb(data_series,Image); 
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                 
            end
            %            
        end
        
        %------------------------------------------------------------------                
        function Load_tvb_from_Dataset(obj,data_series,~)
            [ Dataset, ~ ] = select_Dataset(obj.session,obj.userid,'Select Bckg Dataset:');             
            if isempty(Dataset), return, end;            
            try
                obj.load_tvb(data_series,Dataset);
            catch err
                errordlg('Wrong input: Dataset should contain single-plane images of proper size');
                [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);                
            end            
        end
                
        %------------------------------------------------------------------        
        function Load_IRF_FOV(obj,data_series,~)
            %
            if ~isempty(obj.plate)                
                image = select_Image(obj.session,obj.userid,obj.plate);                
            elseif ~isempty(obj.dataset)
                image = select_Image(obj.session,obj.userid,obj.dataset);
            else
                errordlg('Please set Dataset or Plate before trying to load IRF'); 
                return; 
            end;
            %
            if ~isempty(image) 
                try
                    obj.selected_channel = obj.get_single_channel_IRF_FOV(image,data_series);
                catch err
                    [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                    
                end
            end
            %
        end                          
               
        %------------------------------------------------------------------        
        function Load_IRF_annot(obj,data_series,~)
            %
            if ~isempty(obj.dataset)
                parent = obj.dataset;
            elseif ~isempty(obj.plate)
                parent = obj.plate;
            else
                errordlg('please set Dataset or Plate and load the data before loading IRF'), return;
            end;
            %    
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Please choose IRF file');
            %
            if isempty(str)
                return;
            elseif -1 == str
                % try to look for annotations of data_series' first image..                
                if ~isempty(data_series.image_ids)
                    myimages = getImages(obj.session,data_series.image_ids(1));
                    image = myimages(1);
                    [str, fname] = select_Annotation(obj.session,obj.userid,image,'Choose image(1) IRF');
                end
            end;       
            %
            if isempty(str)                
                return;
            elseif -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
            %
            if strcmp('sdt',fname(numel(fname)-2:numel(fname)))
                fwrite(fid,typecast(str,'uint16'),'uint16');
            else                
                fwrite(fid,str,'*uint8');
            end
            %
            fclose(fid);
            %
            try
                data_series.load_irf(full_temp_file_name);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            %
            delete(full_temp_file_name); %??
        end            
                        
        %------------------------------------------------------------------
        function tempfilename = load_imagefile(obj,~,~)    
            %
            tempfilename = [];            
            %
            if isempty(obj.dataset)
                [ Dataset, ~ ] = select_Dataset(obj.session,obj.userid,'Select a Dataset:');             
                if isempty(Dataset), return, end;                
            else
                Dataset = obj.dataset;
            end;
            %    
            image = select_Image(obj.session,obj.userid,Dataset);                       
            if isempty(image), return, end;
            %   
            try
                % single plane (not time-resolved) so set sizet to 1
                ZCT = get_ZCT(image,'ModuloAlongC',1);
                
                %create a dummy metadata in order to get data via
                %OMERO_fetch
                mdta.FLIM_type = '?';
                mdta.modulo = 'ModuloAlongC';
                mdta.delays = 1;
                
                [ data_cube, ~ ] =  obj.OMERO_fetch(  image, ZCT, mdta);
                            
                data = double(squeeze(data_cube));
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
        function Export_Fitting_Results(obj,fit_controller,data_series,fittingparamscontroller)
            %
            if ~fit_controller.has_fit || isempty(data_series.ZCT)
                 errordlg('There are no analysis results (or not freshly fitted) - nothing to Export');
                 return;
            end
            %
            % get first parameter image just to get the size
            res = fit_controller.fit_result;
            params = res.fit_param_list();
            n_params = length(params);
            %
            param_array(:,:) = fit_controller.get_image(1, params{1});
            
                sizeY = size(param_array,1);
                sizeX = size(param_array,2);
            %
            Z_str = num2str(cell2mat(data_series.ZCT(1)));
            T_str = num2str(cell2mat(data_series.ZCT(3)));
            if data_series.polarisation_resolved                
                    chnls = cell2mat(obj.selected_channel);
                    C_str = [num2str(chnls(1)) num2str(chnls(2))];                
            else
                    C_str = num2str(cell2mat(data_series.ZCT(2)));
            end
            %
            if ~isempty(obj.dataset)
                %
%                 dName = char(java.lang.String(obj.dataset.getName().getValue()));
%                 pName = char(java.lang.String(obj.project.getName().getValue()));
%                 name = [ pName ' : ' dName ];
%                 %
%                 choice = questdlg(['Do you want to Export current results on ' name ' to OMERO? It might take some time.'], ...
%                                         'Export current analysis' , ...
%                                         'Export','Cancel','Cancel');              
%                 if strcmp(choice,'Cancel'), return, end;
%                 %
                current_dataset_name = char(java.lang.String(obj.dataset.getName().getValue()));    

                if ~data_series.polarisation_resolved
                    new_dataset_name = [current_dataset_name ' FLIM fitting channel ' ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                else
                    new_dataset_name = [current_dataset_name ' FLIM fitting: Polarization channels ' ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                    
                end

                description  = ['analysis of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
                newdataset = create_new_Dataset(obj.session,obj.project,new_dataset_name,description);                                                                                                    
                %
                if isempty(newdataset)
                    errordlg('Can not create new Dataset');
                    return;
                end
                %
                hw = waitbar(0, 'Exporting fitting results to Omero, please wait');
                                
                for dataset_index = 1:data_series.n_datasets
                    %
                    if data_series.use(dataset_index)
                        data = zeros(n_params,sizeX,sizeY);
                            for p = 1:n_params,                                                                                                                                            
                                data(p,:,:) = fit_controller.get_image(dataset_index, params{p})';
                            end
                        %                  
                        new_image_description = ' ';

                            new_image_name = char(['FLIM fitting channel ' ...
                                ' Z ' Z_str ...
                                ' C ' C_str ...
                                ' T ' T_str ' ' ...
                                ' _@@_ ' ...
                                data_series.names{dataset_index}]);                                    

                        imageId = obj.fit_results2omeroImage_Channels(data, 'double', new_image_name, new_image_description, res.fit_param_list());                    
                        link = omero.model.DatasetImageLinkI;
                        link.setChild(omero.model.ImageI(imageId, false));
                        link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false));
                        obj.session.getUpdateService().saveAndReturnObject(link); 
                    end;
                    %   
                    waitbar(dataset_index/data_series.n_datasets, hw);
                    drawnow;                                                                 
                end;
                delete(hw);
                drawnow;                                  
                
            elseif ~isempty(obj.plate) % work with SPW layout
                
                 str = split(':',data_series.names{1});
                 if 2 ~= numel(str)
                    errordlg('names of FOVs are inconistent - ensure data were loaded from SPW Plate');
                    return;
                 end
                 %
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
                                        for dataset_index = 1:data_series.n_datasets
                                            str = split(':',data_series.names{dataset_index});
                                            imgname = char(str(2));                                        
                                            iid = str2num(str2mat(cellstr(str(1)))); % oops..                                        
                                            if (1==strcmp(imgName,imgname)) && (iid == iId) && data_series.use(dataset_index)
                                                %
                                                if isempty(newplate) % create new plate                                                    
                                                    current_plate_name = char(java.lang.String(obj.plate.getName().getValue()));    
                                                    %
                                                    if ~data_series.polarisation_resolved
                                                        newplate_name = [current_plate_name ' FLIM fitting channel ' ...
                                                        ' Z ' Z_str ...
                                                        ' C ' C_str ...
                                                        ' T ' T_str ' ' ...
                                                        datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                                                    else
                                                        newplate_name = [current_plate_name ' FLIM fitting: Polarization channels ' ...
                                                        ' Z ' Z_str ...
                                                        ' C ' C_str ...
                                                        ' T ' T_str ' ' ...
                                                        datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                                                     
                                                    end
                                                    %
                                                    if ~isempty(data_series.FLIM_modality), newplate_name = [ data_series.FLIM_modality ' ' newplate_name ]; end;                                                                                                       
                                                    %
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
                                                    % check if the well with the same row,col as of the current image, aready exists in the new (target) plate 
                                                    newwell = [];
                                                    newwellList = obj.session.getQueryService().findAllByQuery(['select well from Well as well '...
                                                        'left outer join fetch well.plate as pt '...
                                                        'left outer join fetch well.wellSamples as ws '...
                                                        'left outer join fetch ws.plateAcquisition as pa '...
                                                        'left outer join fetch ws.image as img '...
                                                        'left outer join fetch img.pixels as pix '...
                                                        'left outer join fetch pix.pixelsType as pt '...
                                                        'where well.plate.id = ', num2str(newplate.getId().getValue())],[]);
                                                    for curwellind = 0:newwellList.size()-1,
                                                        curwell = newwellList.get(curwellind);
                                                        if curwell.getRow() == well.getRow()  && curwell.getColumn() == well.getColumn()
                                                            newwell = curwell;
                                                            break;
                                                        end
                                                    end
                                                    % if there is no well with specified row,col in the new plate - create new well 
                                                    if isempty(newwell) 
                                                        newwell = omero.model.WellI;    
                                                        newwell.setRow(well.getRow());
                                                        newwell.setColumn(well.getColumn());
                                                        newwell.setPlate( omero.model.PlateI(newplate.getId().getValue(),false) );
                                                        newwell = updateService.saveAndReturnObject(newwell);                                                        
                                                    end                                                    
                                                    %
                                                    newws = omero.model.WellSampleI();
                                                        %results image                                       
                                                        data = zeros(n_params,sizeX,sizeY);
                                                                for p = 1:n_params,
                                                                    data(p,:,:) = fit_controller.get_image(dataset_index, params{p})';                                                                    
                                                                end                                                                                  
                                                            new_image_description = ' ';
                                                            
                                                                new_image_name = char(['FLIM fitting channel ' ...
                                                                    ' Z ' Z_str ...
                                                                    ' C ' C_str ...
                                                                    ' T ' T_str ' ' ...
                                                                    ' _@@_ ' ...
                                                                    data_series.names{dataset_index}]);                                    
                                                                                                                                                                                                                                                                                                            
                                                            new_imageId = obj.fit_results2omeroImage_Channels(data, 'double', new_image_name, new_image_description, res.fit_param_list());
                                                        %results image
                                                    newws.setImage( omero.model.ImageI(new_imageId,false) );
                                                    newws.setWell( newwell );        
                                                    %
                                                    newwell.addWellSample(newws);
                                                    newws = updateService.saveAndReturnObject(newws);                                                                                                                                               

                                                    z = z + 1; % param image count
                                                    waitbar(z/data_series.n_datasets, hw);
                                            end % put new well into new plate                                       
                                        end                                                                        
                                end
                            end
                            delete(hw);
                            drawnow;    
            else
                return; % never happens
            end;

                            if exist('newplate','var')
                                object = newplate;
                                msgbox(['the analysis dataset ' newplate_name ' has been created']);                                
                            elseif exist('newdataset','var')
                                object = newdataset;
                                msgbox(['the analysis dataset ' new_dataset_name ' has been created']);                                
                            end;  
                         
                % fitting results table      
                namespace = 'IC_PHOTONICS';
                description = ' ';            
                sha1 = char('pending');
                file_mime_type = char('application/octet-stream');

                root = tempdir;
                param_table_name = [' Fit Results Table ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.csv'];
                fit_controller.save_param_table([root param_table_name]);
                add_Annotation(obj.session, obj.userid, ...
                                object, ...
                                sha1, ...
                                file_mime_type, ...
                                [root param_table_name], ...
                                description, ...
                                namespace);
                %
                % data settings
                data_settings_name = [' data settings ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
                data_series.save_data_settings([root data_settings_name]);
                add_Annotation(obj.session, obj.userid, ...
                                object, ...
                                sha1, ...
                                file_mime_type, ...
                                [root data_settings_name], ...
                                description, ...
                                namespace);               

                % fitting settings
                fitting_settings_name = [' fitting settings ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
                fittingparamscontroller.save_fitting_params([root fitting_settings_name]);
                add_Annotation(obj.session, obj.userid, ...
                                object, ...
                                sha1, ...
                                file_mime_type, ...
                                [root fitting_settings_name], ...
                                description, ...
                                namespace);                                                                                                                               
                                            
        end            

        %------------------------------------------------------------------        
        function Export_Fitting_Settings(obj,fitting_params_controller,~)
            %
            choice = questdlg('Do you want to Export fitting settings to Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object, ~ ] = select_Dataset(obj.session,obj.userid,'Select Dataset:'); 
                case 'Plate', 
                    [ object, ~ ] = select_Plate(obj.session,obj.userid,'Select Plate:'); 
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
            add_Annotation(obj.session, obj.userid, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            fname, ...
                            description, ...
                            namespace);               
        end            
        
        %------------------------------------------------------------------
        function Import_Fitting_Settings(obj,fitting_params_controller,~)
            %
             if ~isempty(obj.dataset) 
                parent = obj.dataset;
             elseif ~isempty(obj.plate) 
                parent = obj.plate;
             else
                errordlg('please set a Dataset or a Plate'), return;
             end;            
            
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose fitting settings file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
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
            
            settings = [];
            
            % look in FLIMfit/dev for logon file
            folder = getapplicationdatadir('FLIMfit',true,true);
            subfolder = [folder filesep 'Dev']; 
            if exist(subfolder,'dir')
                logon_filename = [ subfolder filesep obj.omero_logon_filename ];
                if exist(logon_filename,'file') 
                    [ settings, ~ ] = xml_read (logon_filename);    
                    obj.logon = settings.logon;
                end
                
            end
            
            keeptrying = true;
           
            while keeptrying 
                
            if ~ispref('GlobalAnalysisFrontEnd','OMEROlogin')
                neverTriedLog = true;       % set flag if the OMERO dialog login has never been called on this machine
            else
                neverTriedLog = false;
            end
                
            
            % if no logon file then user must login
            if isempty(settings)
                obj.logon = OMERO_logon();
            end
           
                                    
           if isempty(obj.logon{3})
               if neverTriedLog == true
                   ret_string = questdlg('Respond "Yes" ONLY if you intend NEVER to use FLIMfit with OMERO on this machine!');
                   if strcmp(ret_string,'Yes')
                        addpref('GlobalAnalysisFrontEnd','NeverOMERO','On');
                   end
               end
               return
           end
            
                keeptrying = false;     % only try again in the event of failure to logon
          

                obj.client = loadOmero(obj.logon{1});


                try 
                    obj.session = obj.client.createSession(obj.logon{2},obj.logon{3});
                catch err
                    obj.client = [];
                    obj.session = [];

                    % Construct a questdlg with three options
                    choice = questdlg('OMERO logon failed!', ...
                    'Logon Failure!', ...
                    'Try again to logon','Run FLIMfit in non-OMERO mode','Launch FLIMfit in non-OMERO mode');
                    % Handle response
                    switch choice
                        case 'Try again to logon'
                            keeptrying = true;
                      
                            
                        case 'Run FLIMfit in non-OMERO mode'
                            % no action keeptrying is already false
                       
                    end    % end switch           
                end   % end catch
                if ~isempty(obj.session)
                    obj.client.enableKeepAlive(60); % Calls session.keepAlive() every 60 seconds
                    obj.userid = obj.session.getAdminService().getEventContext().userId;                    
                end
            end     % end while                        
            
        end
       %------------------------------------------------------------------        
       function Omero_logon_forced(obj,~) 
                        
            keeptrying = true;
           
            while keeptrying 
            
            obj.logon = OMERO_logon();
                                    
           if isempty(obj.logon)
               return
           end
            
                keeptrying = false;     % only try again in the event of failure to logon
          
                obj.client = loadOmero(obj.logon{1});

                try 
                    obj.session = obj.client.createSession(obj.logon{2},obj.logon{3});
                catch err
                    obj.client = [];
                    obj.session = [];

                    % Construct a questdlg with three options
                    choice = questdlg('OMERO logon failed!', ...
                    'Logon Failure!', ...
                    'Try again to logon','Run FLIMfit in non-OMERO mode','Run FLIMfit in non-OMERO mode');
                    % Handle response
                    switch choice
                        case 'Try again to logon'
                            keeptrying = true;
                      
                            
                        case 'Run FLIMfit in non-OMERO mode'
                            % no action keeptrying is already false
                       
                    end    % end switch           
                end   % end catch
                if ~isempty(obj.session)
                    obj.client.enableKeepAlive(60); % Calls session.keepAlive() every 60 seconds
                    obj.userid = obj.session.getAdminService().getEventContext().userId;                                        
                end
            end     % end while     
            
       end
        
       %------------------------------------------------------------------        
        function Load_Plate_Metadata_annot(obj,data_series,~)
            %
            if ~isempty(obj.dataset)
                parent = obj.dataset;
            elseif ~isempty(obj.plate)
                parent = obj.plate;
            else
                errordlg('please set Dataset or Plate and load the data before loading plate metadata'), return;
            end;
            %    
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose metadata xlsx file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');                
            fwrite(fid,str,'int8');                        
            fclose(fid);                                                
            %
            try
                data_series.import_plate_metadata(full_temp_file_name);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            %
            delete(full_temp_file_name); %??
        end      
       %------------------------------------------------------------------                
        function Export_IRF_annot(obj,irf_data,~)
            
               choice = questdlg('Do you want to Export IRF to Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object, ~ ] = select_Dataset(obj.session,obj.userid,'Select Dataset:'); 
                case 'Plate', 
                    [ object, ~ ] = select_Plate(obj.session,obj.userid,'Select Plate:'); 
                case 'Cancel', 
                    return;
            end                        
            %                        
            ext = '.irf';   
            irf_file_name = [tempdir 'IRF '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') ext];            
            % works - but why is it t axis distortion there if IRF is from single-plane-tif-averaging
            dlmwrite(irf_file_name,irf_data);            
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            irf_file_name, ...
                            description, ...
                            namespace);                        
        end                
       %------------------------------------------------------------------                        
        function Export_TVB_annot(obj,data_series,~)

            choice = questdlg('Do you want to Export TVB to Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object, ~ ] = select_Dataset(obj.session,obj.userid,'Select Dataset:'); 
                case 'Plate', 
                    [ object, ~ ] = select_Plate(obj.session,obj.userid,'Select Plate:'); 
                case 'Cancel', 
                    return;
            end                        
            %
            if ~exist('object','var') || isempty(object), return, end;
            %
            tvbdata = [data_series.t(:) data_series.tvb_profile(:)];
            %
            ext = '.txt';   
            tvb_file_name = [tempdir 'TVB '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') ext];            
            %
            dlmwrite(tvb_file_name,tvbdata);            
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            tvb_file_name, ...
                            description, ...
                            namespace);                                                            
        end                 
       %------------------------------------------------------------------        
        function Load_TVB_annot(obj,data_series,~)
            %
            if ~isempty(obj.dataset)
                parent = obj.dataset;
            elseif ~isempty(obj.plate)
                parent = obj.plate;
            else
                errordlg('please set Dataset or Plate and load the data before loading TVB'), return;
            end;
            %    
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose TVB file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');                
            fwrite(fid,str,'*uint8');                        
            fclose(fid);
            %
            try
                data_series.load_tvb(full_temp_file_name);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            %
            delete(full_temp_file_name); %??            
        end                      
    %
        %------------------------------------------------------------------        
        function Export_Data_Settings(obj,data_series,~)
            %
            choice = questdlg('Do you want to Export data settings to Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object, ~ ] = select_Dataset(obj.session,obj.userid,'Select Dataset:'); 
                case 'Plate', 
                    [ object, ~ ] = select_Plate(obj.session,obj.userid,'Select Plate:'); 
                case 'Cancel', 
                    return;
            end                        
            %                        
            fname = [tempdir 'data settings '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
            data_series.save_data_settings(fname);         
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            fname, ...
                            description, ...
                            namespace);               
        end            
        
        %------------------------------------------------------------------
        function Import_Data_Settings(obj,data_series,~)
            %
             if ~isempty(obj.dataset) 
                parent = obj.dataset;
             elseif ~isempty(obj.plate) 
                parent = obj.plate;
             else
                errordlg('please set a Dataset or a Plate'), return;
             end;            
            
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose data settings file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
                fwrite(fid,str,'*uint8');
            fclose(fid);
            %
            try
                data_series.load_data_settings(full_temp_file_name);
                delete(full_temp_file_name); 
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end;
        end 
        
        %------------------------------------------------------------------
        function Select_Another_User(obj,~)
                   
            ec = obj.session.getAdminService().getEventContext();
            AdminServicePrx = obj.session.getAdminService();            
                        
            groupids = toMatlabList(ec.memberOfGroups);                  
            gid = groupids(1); %default - first group is the current?                                   
            experimenter_list_g = AdminServicePrx.containedExperimenters(gid);
                                    
            z = 0;
            for exp = 0:experimenter_list_g.size()-1
                exp_g = experimenter_list_g.get(exp);
                z = z + 1;
                nme = [num2str(exp_g.getId.getValue) ' @ ' char(java.lang.String(exp_g.getOmeName().getValue()))];
                str(z,1:length(nme)) = nme;                                                
            end                
                        
            strcell_sorted = sort_nat(unique(cellstr(str)));
            str = char(strcell_sorted);
                                    
            EXPID = [];
            prompt = 'Please choose the user';
            [s,v] = listdlg('PromptString',prompt,...
                                        'SelectionMode','single',...
                                        'ListSize',[300 300],...                                        
                                        'ListString',str);                        
            if(v)
                expname = str(s,:);
                expnamesplit = split('@',expname);
                EXPID = str2num(char(expnamesplit(1)));
            end;                                            

            if ~isempty(EXPID) 
                obj.userid = EXPID;
            else
                obj.userid = obj.session.getAdminService().getEventContext().userId;                
            end                                                                     
            %
            obj.project = [];
            obj.dataset = [];
            obj.screen = [];
            obj.plate = [];
            %
        end          
            
    end
end






























