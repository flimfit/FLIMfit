%     Copyright (C) 2013 Imperial College London.
%     All rights reserved.
%     
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
%     
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%     
%     You should have received a copy of the GNU General Public License along
%     with this program; if not, write to the Free Software Foundation, Inc.,
%     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%     
%     This software tool was developed with support from the UK 
%     Engineering and Physical Sciences Council 
%     through  a studentship from the Institute of Chemical Biology 
%     and The Wellcome Trust through a grant entitled 
%     "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

function infostring = load_fitted_data(obj,f,~) %f : flim_fit_controller
            %
            infostring = [];
            %
            session = obj.omero_data_manager.session;
            userid = obj.omero_data_manager.userid;
            %
            choice = questdlg('Do you want to visualize fitted Dataset or Plate?', ' ', ...
                                    'Dataset' , ...
                                    'Plate','Cancel','Cancel');              
            switch choice
                case 'Dataset',
                    [ object, parent ] = select_Dataset(session,userid,'Select Dataset:'); 
                case 'Plate', 
                    [ object, parent ] = select_Plate(session,userid,'Select Plate:'); 
                case 'Cancel', 
                    return;
            end  
            %
            obj.fit_result = f.fit_result;
            %                                    
            if isempty(object), return, end; 
            
            if ~isempty(parent)
                pName = char(java.lang.String(parent.getName().getValue()));
                pIdName = num2str(parent.getId().getValue());
            else
                pName = 'NO PARENT!';
                pIdName = 'XXXX';
            end;
            oName = char(java.lang.String(object.getName().getValue()));                    
            oIdName = num2str(object.getId().getValue());                       
            infostring = [ 'VISUALIZING: ' choice ' ' oName '" [' oIdName '] @ Parent "' pName '" [' pIdName ']' ];                        
                               
            if strcmp('Dataset',choice) 
                %                
                imageList = getImages(session,'dataset',object.getId().getValue());
                %
            elseif strcmp('Plate',choice) 
                %
                z = 0;       
                wellList = session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(object.getId().getValue())],[]);
                for j = 0:wellList.size()-1,
                    well = wellList.get(j);
                    wellsSampleList = well.copyWellSamples();
                    well.getId().getValue();
                    for i = 0:wellsSampleList.size()-1,
                        ws = wellsSampleList.get(i);
                        ws.getId().getValue();
                        z = z + 1;
                        imageList(z) = ws.getImage();
                     end
                end                                   
            end                
                
                z = 0;       
                str = char(512,512); % ?????
                for k = 1:imageList.size(),                       
                    z = z + 1;                                                       
                    iName = char(java.lang.String(imageList(k).getName().getValue()));                                                                
                        str(z,1:length(iName)) = iName;
                 end 
                %
                FOV_names = sort_nat(cellstr(str)); % OK
                %
                [FOV_names, ~, data_series.lazy_loading] = dataset_selection(FOV_names);            
                %
                n_FOVs = length(FOV_names);
                %
                % find corresponding FOVs...
                for m = 1:n_FOVs
                    iName_m = FOV_names{m};
                    for k = 1:imageList.size(),                       
                             iName_k = char(java.lang.String(imageList(k).getName().getValue()));
                             if strcmp(iName_m,iName_k)
                                FOVs(m) = imageList(k);
                                break;
                             end;
                    end 
                end
                %
                FOV_names_noble = FOV_names;
                for m = 1:n_FOVs
                    iName_m = FOV_names{m};
                    if isempty(strfind(iName_m,'_@@_')) || isempty(strfind(iName_m,'fitting'))
                        errordlg('at least one of the images does not repersent fitted FLIM results - can not continue');
                        return;
                    end
                    %
                    piv = strfind(iName_m,' _@@_ ');
                    FOV_names_noble{m} = iName_m(piv+6:length(iName_m));
                end
                %
                FOV_names = FOV_names_noble;
                %                                                                 

            table_data = read_analysis_stats_data_from_annotation(obj,object.getId().getValue());
            if isempty(table_data), errordlg('FOV statistics annotation file missing - can not continue'), 
                return, 
            end;
                        
            % dimensions..             
                 pixelsList = imageList(1).copyPixels();    
                 pixels = pixelsList.get(0);
                 SizeC = pixels.getSizeC().getValue();
                 SizeZ = pixels.getSizeZ().getValue();
                 SizeT = pixels.getSizeT().getValue();
                 SizeX = pixels.getSizeY().getValue(); 
                 SizeY = pixels.getSizeX().getValue();
                 %
                 if SizeZ~=1 || SizeT~=1, errordlg('wrong Z or T dimension - can not continue'), return, end;
                 %
                 obj.fitted_data = single(zeros(n_FOVs,SizeX,SizeY,SizeC));                 
                 %
                 %names....
                 param_names = cell(1,SizeC);
                 pixelsService = session.getPixelsService();
                 image = imageList(1);
                 pixelsList = image.copyPixels();    
                 pixels = pixelsList.get(0);                 
                 pixelsDesc = pixelsService.retrievePixDescription(pixels.getId().getValue());
                 channels = pixelsDesc.copyChannels();
                 %         
                 for c = 1:SizeC
                        ch = channels.get(c - 1);
                        param_names{c} = char(ch.getLogicalChannel().getName().getValue());
                 end       
                 % names...
                 %
                 wait_handle=waitbar(0,'filling fitted data for visualization...');
                 for m = 1:n_FOVs
                     %image = imageList(m);
                     image = FOVs(m);
                         pixelsList = image.copyPixels();    
                         pixels = pixelsList.get(0);
                         pixelsId = pixels.getId().getValue();
                         image.getName().getValue();
                         store = session.createRawPixelsStore(); 
                         store.setPixelsId(pixelsId, false);                                                
                     for c = 1:SizeC
                         rawPlane = store.getPlane(0, c-1, 0);  
                         plane = toMatrix(rawPlane, pixels);                          
                         obj.fitted_data(m,:,:,c) = single(plane');
                     end
                     waitbar(m/n_FOVs,wait_handle);
                 end;
                 close(wait_handle);
            
            % now one needs to fill it...
            data_size = [ 1 1 SizeX SizeY ];
                        
            obj.n_datasets = n_FOVs;
            obj.names = FOV_names;
            %                        

% LEAVE THIS FOR A MOMENT... May 22..
%             obj.polarisation_resolved & length(obj.selected_channel) ~= 2                
%                 errordlg('Two channels must be selected for polarization data');
%                 return;
%             end
                        
            obj.data_size = [ data_size n_FOVs ];
                
            delays = 1;
                                   
                obj.file_names = {'file'};
                                 
                try
                    obj.metadata = extract_metadata(obj.names);        
                catch err
                    [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);  
                end
                                                
                obj.t = delays;
                
%                 if strcmp(obj.mode,'TCSPC')
%                     obj.t_int = ones(size(obj.t));      % Not sure of behaviour for gated data
%                 end
                             
                obj.clear_memory_mapping();                
                obj.loaded = false(1,n_FOVs);
                
%%%%%%%%%%%%%%%%%%%%%%%%% use prev loaded fitted_data to fill images
selected = 1:obj.n_datasets;

if ~isempty(obj.loaded)
        already_loaded = true;
        for i=1:length(selected)
            if ~obj.loaded(selected(i))
                already_loaded = false;
            end
        end

        if already_loaded
            return;
        end
end

    if obj.use_popup && length(selected) > 1 
        wait_handle=waitbar(0,'filling image intensities...');
        using_popup = true;
    else
        using_popup = false;
        obj.verbose = true;
    end
    
    obj.clear_memory_mapping();

    obj.loaded = false(1, obj.n_datasets);
    num_sel = length(selected);

    for j=1:num_sel
        obj.loaded(selected(j)) = true;
    end
    
    intensity_idx = strcmp(param_names,'I');
    intensity_idx = find(intensity_idx);    
            
        obj.use_memory_mapping = false; % mmmmmmmmmmm
    
        if obj.use_memory_mapping
            
            % whatever            
            
        else    % no memory mapping
           
            for j=1:num_sel
                
                  sizet = 1;
                  nchans = 1;              
                  
              U = single(zeros(sizet,nchans,SizeX,SizeY,1));
                            
              U(sizet,nchans,:,:,1) = obj.fitted_data(j,:,:,intensity_idx);
              obj.data_series_mem(:,:,:,:,j) = U;
                
                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end
                        
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);                
    obj.init_dataset();            
                                                       
            f.selected = (1:n_FOVs);            
            f.fit_result.image = (1:n_FOVs);
            f.fit_result.names = obj.names'; 
            f.fit_result.set_param_names(param_names); % !
            f.fit_result.n_results = n_FOVs;
            f.fit_result.intensity_idx = intensity_idx;
            f.fit_result.width = SizeY;
            f.fit_result.height = SizeX;
            f.fit_result.ready = 1; 
            f.fit_result.is_temp = 1;
                        
    % Get metadata for the datasetes we've just fit
    md = obj.metadata;
    fields = fieldnames(md);
    for i=1:length(fields)
        ff = md.(fields{i});
        md.(fields{i}) = ff(f.fit_result.image);
    end    
    f.fit_result.metadata = md;
    % AFTER metadata filled, can call this function
    f.fit_result.set_stats_from_table(table_data');
                                   
    f.dll_interface.fit_result = [];
     
    f.display_fit_end();

%     if ishandle(obj.table_stat_popupmenu)
%         set(f.table_stat_popupmenu,'String',f.fit_result.stat_names);
%     end
    
%    f.update_table();

    f.has_fit = true;
    f.fit_in_progress = false;    
    f.update_progress([],[]);
        
    f.selected = 1:f.fit_result.n_results;

    f.update_filter_table();
    f.update_list();
    f.update_display_table();
   
    try
    notify(f,'fit_updated');    
    catch ME
        getReport(ME)
    end
    notify(f,'fit_completed');    
            
    if f.refit_after_return
        f.refit_after_return = false;
        f.fit(true);
    end
                        
end

        
    

