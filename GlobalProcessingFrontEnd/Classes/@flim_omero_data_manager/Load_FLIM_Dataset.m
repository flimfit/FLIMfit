function Load_FLIM_Dataset(obj,data_series,~)                        
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

            % DEBUG
            data_series.use_memory_mapping = false;
            
              
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
                n_datasets = length(folder_names);
                %
                image_ids = zeros(1,n_datasets); %sorted
                %
                for m = 1:n_datasets
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
                    errordlg('Dataset has no images - please choose a Dataset with images');
                    return;
                end;                                    
                %        
                z = 0;       
                str = char(512,256); % ?????
                for k = 0:imageList.size()-1,                       
                    z = z + 1;                                                       
                    iName = char(java.lang.String(imageList.get(k).getName().getValue()));                                                                
                   % A = split('.',iName);
                   % if true % strcmp(extension,A(length(A))) 
                        str(z,1:length(iName)) = iName;
                   %end;
                 end 
                %
                folder_names = sort_nat(cellstr(str));
                %
                [folder_names, ~, data_series.lazy_loading] = dataset_selection(folder_names);            
                %
                n_datasets = length(folder_names);
                %
                % find corresponding Image ids list...
                image_ids = zeros(1,n_datasets);
                for m = 1:n_datasets
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
            data_series.n_datasets = n_datasets;
            data_series.names = cell(1,n_datasets);
            %
            % set names
            extensions{1} = '.ome.tiff';
            extensions{2} = '.ome.tif';
            extensions{3} = '.tif';
            extensions{4} = '.tiff';
            extensions{5} = '.sdt';                        
                for j=1:n_datasets
                    string = folder_names{j};
                    for extind = 1:numel(extensions)    
                        string = strrep(string,extensions{extind},'');
                    end
                    data_series.names{j} = string;
                end
            %                
            if 0==numel(image_ids), return, end;
                                              
            myimages = getImages(obj.session,image_ids(1)); image = myimages(1);
            %
            mdta = get_FLIM_params_from_metadata(obj.session,image);
            if isempty(mdta) || isempty(mdta.delays)
                errordlg('can not load: data have no FLIM specification');
                return;
            end  
            
            delays = mdta.delays;
            
            data_series.ZCT = get_ZCT(image, mdta.modulo, length(delays), data_series.polarisation_resolved);
            obj.selected_channel = data_series.ZCT{2}
            
            
            
            data_series.verbose = false;     % suppress low-level waitbar if loading mutiple images
           
            
            data_size = [ length(delays) length(obj.selected_channel) mdta.sizeX mdta.sizeY ];
           
            
            data_series.mode = mdta.FLIM_type;
            data_series.mdta = mdta;
                        
           
            data_series.data_size = [data_size n_datasets ];
                
           
                   
            if length(delays) > 0 
                
                data_series.file_names = {'file'};
                data_series.channels = 1;
                
                data_series.session = obj.session;      % copy current session into OMERO_data_series
                 
                try
                    data_series.metadata = extract_metadata(data_series.names);        
                catch err
                    [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);  
                end
                                
                
                data_series.t = delays;
                
                if strcmp(data_series.mode,'TCSPC')
                    data_series.t_int = ones(size(data_series.t));      % Not sure of behaviour for gated data
                end
             
                
                data_series.clear_memory_mapping();
                
                data_series.loaded = false(1,n_datasets);
                
                data_series.image_ids = image_ids;
                data_series.mdta = mdta;
               
                
                
                
                if data_series.lazy_loading
                    data_series.load_selected_files(1);
                else
                    data_series.load_selected_files(1:n_datasets);
                end
               
               
               
               
                data_series.compute_tr_data(false);    
               
                                
                data_series.init_dataset();            
                
            end % if length(delays) > 0
            
end            
