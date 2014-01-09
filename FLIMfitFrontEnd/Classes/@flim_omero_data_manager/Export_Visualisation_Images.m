function Export_Visualisation_Images(obj,plot_controller,data_series,flimfitparamscontroller,~)                        
                
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
    
    if ~plot_controller.fit_controller.has_fit || ... 
            (~isempty(plot_controller.fit_controller.fit_result.binned) && plot_controller.fit_controller.fit_result.binned == 1) || ...
            isempty(data_series.ZCT)
        errordlg('..mmm.. can not continue - or no data, or reloaded data. Presently FLIM maps might be transferred only from freshly fitted data)..');
        return;
    end
    
    indexing = 'result';
    
    f = plot_controller.fit_controller;
    r = f.fit_result;
            
    updateService = obj.session.getUpdateService();    
    %
    Z_str = num2str(cell2mat(data_series.ZCT(1)));
    T_str = num2str(cell2mat(data_series.ZCT(3)));
    if data_series.polarisation_resolved                
        chnls = cell2mat(obj.selected_channel);
        C_str = [num2str(chnls(1)) num2str(chnls(2))];                
    else
        C_str = num2str(cell2mat(data_series.ZCT(2)));
    end
    
    if ~isnumeric(obj.selected_channel)
        selected_channel = num2str(cell2mat(obj.selected_channel));
    else
        selected_channel = obj.selected_channel;
    end
    
    f_save = figure('visible','on');        
    save = true;        
    root = tempdir;    
        
    if ~isempty(obj.dataset)
                %
                current_dataset_name = char(java.lang.String(obj.dataset.getName().getValue()));    

                if ~data_series.polarisation_resolved
                    
                    new_dataset_name = [current_dataset_name ' FLIM MAPS ' selected_channel ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                else
                    new_dataset_name = [current_dataset_name ' FLIM MAPS Polarization channel ' C_str ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                    
                end

                newdataset_description  = ['analysis FLIM maps of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
                newdataset = create_new_Dataset(obj.session,obj.project,new_dataset_name,newdataset_description);                                                                                                    
                %
                if isempty(newdataset)
                    errordlg('Can not create new Dataset');
                    return;
                end
                                            
    cnt=0; % flimmaps counter    
    nplots = r.n_results*f.n_plots;            
                            hw = waitbar(0, 'Loading FLIM maps to Omero, please wait');            
    ims = 1:r.n_results; % FOVs    
    for cur_im = ims
        name_root = [root ' ' r.names{cur_im}];
        if f.n_plots > 0
            for plot_idx = 1:length(f.plot_names) % selected parameters
            
                if f.display_normal.(f.plot_names{plot_idx})
                    [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    plot_controller.plot_figure(h,c,cur_im,plot_idx,false,'',indexing);                                                                                
                    fname = [name_root ' @ ' r.params{plot_idx}];
                    saveas(h,fname,'tiff');
                    transfer_tif_to_Omero_Dataset(fname);
                        cnt=cnt+1;
                            waitbar(cnt/nplots, hw);
                            drawnow;                                                
                end
                % Merge
                if f.display_merged.(f.plot_names{plot_idx})                    
                    [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);                    
                    plot_controller.plot_figure(h,c,cur_im,plot_idx,true,'',indexing);                  
                    fname = [name_root ' @ ' r.params{plot_idx} ' merge'];                    
                    saveas(h,fname,'tif');
                    transfer_tif_to_Omero_Dataset(fname);                    
                        cnt=cnt+1;
                            waitbar(cnt/nplots, hw);
                            drawnow;        
                end                
            end % for plot_idx = 1:length(f.plot_names)
        end % if f.n_plots > 0                 
    end % for cur_im = ims        
                            delete(hw);
                            drawnow;
                            
    add_annotations(newdataset);
    
    elseif ~isempty(obj.plate) % work with SPW layout    
        %
                            wellList = obj.session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(obj.plate.getId().getValue())],[]);

	newplate = [];
    create_new_Plate('altogether'); % uncomment if want single plate
    thatplateid  = newplate.getId.getValue;% uncomment if want single plate
                        
    cnt=0; % FOVs counter    
    nplots = r.n_results*f.n_plots;            
                                hw = waitbar(0, 'Loading FLIM maps to Omero, please wait');            
    ims = 1:r.n_results;    
        if f.n_plots > 0
            for plot_idx = 1:length(f.plot_names)                                
                if f.display_normal.(f.plot_names{plot_idx})
                    %create output plate...
                    %create_new_Plate(r.params{plot_idx}); % comment out if want single plate
                    %thatplateid  = newplate.getId.getValue; % comment out if want single plate
                    %    
                    for cur_im = ims
                        name_root = [root ' ' r.names{cur_im}];
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                        plot_controller.plot_figure(h,c,cur_im,plot_idx,false,'',indexing);
                        fname = [name_root ' @ ' r.params{plot_idx}];
                        saveas(h,fname,'tif');                        
                        transfer_parameter_images_to_Plate();                        
                            cnt=cnt+1;
                                waitbar(cnt/nplots, hw);
                                drawnow;                            
                    end;                                        
                    %thatplate = get_Object_by_Id(obj.session,thatplateid); % comment out if want single plate
                    %add_annotations(thatplate); % comment out if want single plate                                                  
                end
                % Merge
                if f.display_merged.(f.plot_names{plot_idx})                    
                    %create output plate...              
                    %create_new_Plate([r.params{plot_idx} ' merge']);% comment out if want single plate
                    %thatplateid  = newplate.getId.getValue;% comment out if want single plate
                    %
                    for cur_im = ims
                        name_root = [root ' ' r.names{cur_im}];                                                            
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);                    
                        plot_controller.plot_figure(h,c,cur_im,plot_idx,true,'',indexing);                  
                        fname = [name_root ' @ ' r.params{plot_idx} ' merge'];
                        saveas(h,fname,'tif');                        
                        transfer_parameter_images_to_Plate();                        
                            cnt=cnt+1;
                                waitbar(cnt/nplots, hw);
                                drawnow;        
                    end
                    %thatplate = get_Object_by_Id(obj.session,thatplateid);% comment out if want single plate
                    %add_annotations(thatplate);% comment out if want single plate                                                   
                end % if f.display_normal.(f.plot_names{plot_idx})                
            end % for plot_idx = 1:length(f.plot_names)
        end % f.n_plots > 0 

        thatplate = get_Object_by_Id(obj.session,obj.userid,thatplateid);% uncomment if want single plate
        add_annotations(thatplate);% uncomment if want single plate                                                   
                
        delete(hw);
        drawnow;                
    end                                                
    
    close(f_save);    
      
    function transfer_tif_to_Omero_Dataset(fname)
                            U = imread(fname,'tif');
                            %
                            pixeltype = get_num_type(U);
                            %                                             
                            %str = split(filesep,data.Directory);
                            strings1 = strrep(fname,filesep,'/');
                            str = split('/',strings1);                            
                            file_name = str(length(str));
                            %
                            % rearrange planes
                            [ww,hh,Nch] = size(U);
                            Z = zeros(Nch,hh,ww);
                            for cc = 1:Nch,
                                Z(cc,:,:) = squeeze(U(:,:,cc))';
                            end;
                            img_description = ' ';
                            imageId = mat2omeroImage(obj.session, Z, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                            link = omero.model.DatasetImageLinkI;
                            link.setChild(omero.model.ImageI(imageId, false));
                            link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false)); % in this case, "project" is Dataset
                            obj.session.getUpdateService().saveAndReturnObject(link); 
    end
    
    %
    function create_new_Plate(fitted_parameter_name)
                
        current_plate_name = char(java.lang.String(obj.plate.getName().getValue()));    

                if ~data_series.polarisation_resolved
                    newplate_name = [current_plate_name ' FLIM MAPS ' fitted_parameter_name ' channel ' ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                else
                    newplate_name = [current_plate_name ' FLIM MAPS Polarization channel ' ...
                    ' Z ' Z_str ...
                    ' C ' C_str ...
                    ' T ' T_str ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                    
                end
                
            if ~isempty(data_series.FLIM_modality), newplate_name = [ data_series.FLIM_modality ' ' newplate_name ]; end;
                        
            newplate = omero.model.PlateI();
            newplate.setName(omero.rtypes.rstring(newplate_name));    
            newplate.setColumnNamingConvention(obj.plate.getColumnNamingConvention());
            newplate.setRowNamingConvention(obj.plate.getRowNamingConvention());                                                                    
            newplate = updateService.saveAndReturnObject(newplate);
            newplatelink = omero.model.ScreenPlateLinkI;
            newplatelink.setChild(newplate);            
            newplatelink.setParent(omero.model.ScreenI(obj.screen.getId().getValue(),false));            
            updateService.saveObject(newplatelink);                                                                     
    end

    %
    function transfer_parameter_images_to_Plate()
                
        str = split(':',r.names{cur_im});
        fittedimagename = char(str(2)); 
        fittedimageiid = str2num(str2mat(cellstr(str(1)))); % wtf  
                
        for j = 0:wellList.size()-1,
            well = wellList.get(j);
            wellsSampleList = well.copyWellSamples();
            well.getId().getValue();
                for i = 0:wellsSampleList.size()-1,
                    ws = wellsSampleList.get(i);
                    ws.getId().getValue();
                    %
                    image = ws.getImage();
                    iId = image.getId().getValue();
                    imgName = char(java.lang.String(image.getName().getValue()));
                    %
                    if (1==strcmp(imgName,fittedimagename)) && (fittedimageiid == iId) % put new /well?/ image into new plate
                                                
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
                                                    %fitted parameter image - starts                                                       
                                                    U = imread(fname,'tif');
                                                    %
                                                    pixeltype = get_num_type(U);
                                                    %                                             
                                                    strings1 = strrep(fname,filesep,'/');
                                                    str = split('/',strings1);                            
                                                    file_name = str(length(str));
                                                    %
                                                    % rearrange planes
                                                    [ww,hh,Nch] = size(U);
                                                    Z = zeros(Nch,hh,ww);
                                                            for cc = 1:Nch,
                                                                Z(cc,:,:) = squeeze(U(:,:,cc))';
                                                            end;
                                                    img_description = ' ';
                                                    new_imageId = mat2omeroImage(obj.session, Z, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                                                    %fitted parameter image - end                                                    
                                                    newws.setImage( omero.model.ImageI(new_imageId,false) );
                                                    newws.setWell( newwell );        
                                                    %
                                                    newwell.addWellSample(newws);
                                                    newws = updateService.saveAndReturnObject(newws);
                    end  % if same image name                                  
                end % for wellsSamlpe list
        end % for wellList                                
    end % transfer_parameter_images_to_Plate() function end                

    % 
    function add_annotations(object)
            %
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            % fitting results table                
            param_table_name = [' Fit Results Table ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS') '.csv'];
            plot_controller.fit_controller.save_param_table([root param_table_name]);
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
            flimfitparamscontroller.save_fitting_params([root fitting_settings_name]);
            add_Annotation(obj.session, obj.userid, ...
                            object, ...
                            sha1, ...
                            file_mime_type, ...
                            [root fitting_settings_name], ...
                            description, ...
                            namespace);                                       
    end
end