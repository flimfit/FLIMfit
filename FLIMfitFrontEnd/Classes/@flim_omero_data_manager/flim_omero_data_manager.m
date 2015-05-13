%> @ingroup UserInterfaceControllers
classdef flim_omero_data_manager < handle 
    
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the
    % This program is free software; you can redistribute it  License, or
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
        function Load_Background(obj,data_series,~)
            if ~isempty(obj.plate)                
                image = select_Image(obj.session,obj.userid,obj.plate);                
            elseif ~isempty(obj.dataset)
                image = select_Image(obj.session,obj.userid,obj.dataset);
            else
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return; 
            end;
                                 
            if ~isempty(image)
                data_series.load_background(image)
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
                %try
                    load_as_image = false;
                    data_series.load_irf(image,load_as_image)
                %catch err
                %    [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');                    
                %end
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
            
            [path,name,ext] = fileparts_inc_OME(fname);
            
            % NB marshal-object is overloaded in OMERO_data_series &
            % load_irf uses marshal_object for .xml files so simply call
            % directly
            if strcmp(ext,'.xml') 
                data_series.load_irf(fname);
                return;
            end;
            
            %
            if strcmp(ext,'.sdt')
                fwrite(fid,typecast(str,'uint16'),'uint16');
            else                
                fwrite(fid,str,'*uint8');
            end
            %
            fclose(fid);
            
           
            %try
                data_series.load_irf(full_temp_file_name);
            %catch err
            %     [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            %end
            %
            delete(full_temp_file_name); %??
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
                current_dataset_id = num2str(obj.dataset.getId().getValue());

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

                description  = ['Results from fitting of Dataset '  current_dataset_name  '(' current_dataset_id ') Plane' ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...    
                    '. Created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
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
                    errordlg('names of FOVs are inconsistent - ensure data were loaded from SPW Plate');
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
                data_series.save_data_settings(data_settings_name, object);
                        

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
            
            selected = obj.select_for_annotation();
            
            if isempty(selected)
                return;
            end
                           
            fname = [tempdir 'fitting settings '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.xml'];
            fitting_params_controller.save_fitting_params(fname);         
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            selected, ...
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
                                               
           if isempty(obj.logon{4})
               if neverTriedLog == true
                   ret_string = questdlg('Respond "Yes" ONLY if you intend NEVER to use FLIMfit with OMERO on this machine!');
                   if strcmp(ret_string,'Yes')
                        addpref('GlobalAnalysisFrontEnd','NeverOMERO','On');
                   end
               end
               return
           end
            
                keeptrying = false;     % only try again in the event of failure to logon
                
                try 
                    port = obj.logon{2};
                    if ischar(port), port = str2num(port); end;
                    obj.client = loadOmero(obj.logon{1},port);                                    
                    obj.session = obj.client.createSession(obj.logon{3},obj.logon{4});
                catch err
                    display(err.message);
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
          
                try 
                    port = obj.logon{2};
                    if ischar(port), port = str2num(port); end;
                    obj.client = loadOmero(obj.logon{1},port);                                    
                    obj.session = obj.client.createSession(obj.logon{3},obj.logon{4});
                catch err
                    display(err.message);
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
            
            selected = obj.select_for_annotation();
            
            if isempty(selected)
                return;
            end
            
                                           
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
                            selected, ...
                            sha1, ...
                            file_mime_type, ...
                            irf_file_name, ...
                            description, ...
                            namespace);                        
        end                
       %------------------------------------------------------------------                        
        function Export_TVB_annot(obj,data_series,~)
            
            selected = obj.select_for_annotation();
            
            if isempty(selected)
                return;
            end

            
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
                            selected, ...
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
            
            
           prompt = {'Please Enter File Annotation name'};
           dlg_title = 'Input name';
           num_lines = 1;
           def = {'FLIMfit_settings.xml'};
           file = inputdlg(prompt,dlg_title, num_lines,def);
           if ~isempty(file)
               file = file{1};
               data_series.save_data_settings(file);
           end
            
                       
                       
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
            
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            
            data_series.load_data_settings(fname);
          
        end 
        
        %------------------------------------------------------------------
        % ask user to select a plate or dataset for adding annotations
        function selected = select_for_annotation(obj)
            
            selected = [];
            
            %choice = questdlg('Do you want to Export fitting settings to Dataset or Plate?', ' ', ...
            %                        'Dataset' , ...
            %                       'Plate','Cancel','Cancel');      
            
            % Use only dataset for now pemding Management decision re Plates.
            choice = 'Dataset';
            
            switch choice
                case 'Dataset',
                    chooser = OMEuiUtils.OMEROImageChooser(obj.client, obj.userid, int32(1));
                    selected = chooser.getSelectedDataset();
                    clear chooser
                case 'Plate', 
                    chooser = OMEuiUtils.OMEROImageChooser(obj.client, obj.userid, int32(1));
                    selected = chooser.getSelectedPlate();
                    clear chooser;
                case 'Cancel', 
                    return;
            end
            
            if isempty(selected)
                return;
            end
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






























