function Load_FLIM_Dataset_Polarization(obj,data_series,~)                        
    % data_series MUST BE initiated BEFORE THE CALL OF THIS FUNCTION  
        
        
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


            %
            if isempty(obj.plate) && isempty(obj.dataset)
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return;                 
            end;
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
                [folder_names, ~, data_series.lazy_loading] = dataset_selection(folder_names);   
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
                    errordlg('Dataset have no images - please choose Dataset with images');
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
                [folder_names, ~, data_series.lazy_loading] = dataset_selection(folder_names);            
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
            data_series.num_datasets = num_datasets;                               
            data_series.names = cell(1,num_datasets);
            %
            % set names
            extensions{1} = '.ome.tiff';
            extensions{2} = '.ome.tif';
            extensions{3} = '.tif';
            extensions{4} = '.tiff';
            extensions{5} = '.sdt';                        
                for j=1:num_datasets
                    string = folder_names{j};
                    for extind = 1:numel(extensions)    
                        string = strrep(string,extensions{extind},'');
                    end
                    data_series.names{j} = string;
                end
            %                
            if 0==numel(image_ids), return, end;
            %                                   
            myimages = getImages(obj.session,image_ids(1)); image = myimages(1);
            %
            mdta = get_FLIM_params_from_metadata(obj.session,image);
            if isempty(mdta) || isempty(mdta.delays)
                errordlg('can not load: data have no FLIM specification');
                return;
            end  
            
            delays = mdta.delays;
            
            obj.verbose = false;  % suppress waitbar if loading mutiple images
            if 1==numel(image_ids), obj.verbose = true; end;
            
            channels = data_series.request_channels(true);
            
            obj.ZCT = {1 channels 1}; % temp...          
            
            if data_series.use_popup && data_series.num_datasets > 1 && ~data_series.raw
                wait_handle=waitbar(0,'Loading FLIMages...');
                using_popup = true;
            else
                using_popup = false;
            end
            % ????? !!!!!            
            obj.selected_channel = channels(1)*10 + channels(2); % ?????
            %
            try
                [data_cube, ~] = obj.OMERO_fetch(image, obj.ZCT, mdta);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end     
            %
            if using_popup
                waitbar(1/data_series.num_datasets,wait_handle);
            end            
            %
            data_size = size(data_cube);
            
            data_series.mode = mdta.FLIM_type;
            %
            data_series.data_series_mem(:,:,:,:,1) = single(data_cube);               
            data_series.data_size = data_size;
            %        
            if length(delays) > 0 % ??
                %
                data_series.file_names = {'file'};
                data_series.channels = 1;
                                 
                try
                    data_series.metadata = extract_metadata(data_series.names);        
                catch err
                    [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);  
                end
                                
                data_series.polarisation_resolved = true;
                
                data_series.t = delays;
                
                if strcmp(data_series.mode,'TCSPC')
                    data_series.t_int = ones(size(data_series.t));      % Not sure of behaviour for gated data
                end
                data_series.use_memory_mapping = false;
                data_series.load_multiple_channels = true; 
                %                
                selected = 1:data_series.num_datasets;
                %
                data_series.clear_memory_mapping();
                %
                data_series.loaded = false(1, data_series.n_datasets);
                num_sel = length(selected);

                for j=1:num_sel
                    data_series.loaded(selected(j)) = true;
                end

                if ~data_series.raw % not checked

                    if data_series.use_memory_mapping % this block wasn't checked

                        mapfile_name = global_tempname;
                        mapfile = fopen(mapfile_name,'w');

                        for j = 2:num_sel

                                imgId = image_ids(selected(j));                        
                                %
                                myimages = getImages(obj.session,imgId); image = myimages(1);
                                try
                                    [data,~] = obj.OMERO_fetch(image,obj.ZCT,mdta);
                                catch err
                                    rethrow(err);
                                end                    

                            if isempty(data) || size(data,1) ~= data_series.n_t
                                data = zeros([data_series.n_t data_series.n_chan data_series.height data_series.width]);
                            end

                            c1=fwrite(mapfile,data,'single');

                            if using_popup
                                waitbar(j/num_sel,wait_handle)
                            end

                        end

                        fclose(mapfile);

                        data_series.init_memory_mapping(data_series.data_size(1:4), num_sel, mapfile_name);    

                    else % no memory mapping

                        for j = 2:num_sel

                                imgId = image_ids(selected(j));                        
                                %
                                myimages = getImages(obj.session,imgId); image = myimages(1);
                                try
                                    [data,~] = obj.OMERO_fetch(image,obj.ZCT,mdta);
                                    if ~isempty(data) 
                                        data_series.data_series_mem(:,:,:,:,j) = single(data);                                        
                                    end;
                                catch err
                                    if using_popup, 
                                        close(wait_handle), 
                                    end;                        
                                    rethrow(err);
                                end                                        

                            if using_popup
                                waitbar(j/num_sel,wait_handle)
                            end

                        end

                        data_series.active = 1;
                        data_series.cur_data = data_series.data_series_mem(:,:,:,:,1);

                    end
                    
                else
                    data_series.init_memory_mapping(data_series.data_size(1:4), num_sel, data_series.mapfile_name);
                end

                if using_popup
                    close(wait_handle)
                end

                data_series.compute_tr_data(false);    
                data_series.switch_active_dataset(1);    
                %data_series.init_dataset(dataset_indexting_file); %?   
                                
                data_series.init_dataset();            
                
            end % if length(delays) > 0
            
end            
