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
                          
            if isempty(obj.plate) && isempty(obj.dataset)
                errordlg('Please set Dataset or Plate before trying to load images'); 
                return;                 
            end;
            %
            if ~isempty(obj.plate) 
            %
                list_load_acceptor = [];
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
                                    imageList(z) = image;
                                    iid = image.getId().getValue();
                                    idName = num2str(image.getId().getValue());
                                    iName = char(java.lang.String(image.getName().getValue()));
                                    image_name = [ idName ' : ' iName ];
                                    str(z,1:length(image_name)) = image_name;
                                    imageids_unsorted(z) = iid;
                                end
                            end      
                folder_names_unsorted = cellstr(str);                                            
                %
                % THIS BLOCK SELECTS NEEDED FLIM MODALITY - STARTS
                % temporarily removed !
                % THIS BLOCK SELECTS NEEDED FLIM MODALITY - ENDS
                                                                                
                folder_names = sort_nat(folder_names_unsorted); % sorted
                [folder_names, ~, data_series.lazy_loading] = dataset_selection(folder_names);   
                %
                n_datasets = length(folder_names);
               
                for m = 1:n_datasets
                    iName_m = folder_names{m};
                    for k = 1:numel(folder_names_unsorted)                       
                        iName_k = folder_names_unsorted{k};
                        if strcmp(iName_m,iName_k)
                            selected_images{m} = imageList(k);
                            break;
                        end;
                    end 
                end                                
                %
            elseif ~isempty(obj.dataset) 
                
                imageList = getImages(obj.session, 'dataset', obj.dataset.getId().getValue());
                
                if 0==imageList.size()
                    errordlg('Dataset has no images - please choose a Dataset with images');
                    return;
                end;                                    
                    
                str = char(512,256); % ?????
                for k = 1:length(imageList)                                                                             
                    iName = char(java.lang.String(imageList(k).getName().getValue()));                                                                
                   % A = split('.',iName);
                   % if true % strcmp(extension,A(length(A))) 
                        str(k,1:length(iName)) = iName;
                   %end;
                 end 
                %
                folder_names = sort_nat(cellstr(str));
                                
                %TREAT POSSIBLE ACCEPTOR IMAGES - STARTS
                % removed TBD  via menu item
                %TREAT POSSIBLE ACCEPTOR IMAGES - END                                
                %
                [folder_names, ~, data_series.lazy_loading] = dataset_selection(folder_names);            
                %                                                                                                                                
                n_datasets = length(folder_names);
                %
                % find corresponding Image ids list...
                image_ids = zeros(1,n_datasets);
                for m = 1:n_datasets
                    iName_m = folder_names{m};
                    for k = 1:length(imageList)                      
                             iName_k = char(java.lang.String(imageList(k).getName().getValue()));
                             if strcmp(iName_m,iName_k)
                                selected_images{m} = imageList(k);
                                break;
                             end;
                    end 
                end
                %
            end % Dataset...
           
            data_series.names = cell(1,n_datasets);
            
            %split names into components at full-stops & discard extensions                     
            for j=1:n_datasets
                strings = regexp(folder_names{j}, '\.', 'split');
                data_series.names{j} = strings{1};
            end
                           
            if length(selected_images) == 0
                return;
            end
           
         
            
            data_series.polarisation_resolved = false;
            data_series.load_data_series(selected_images, data_series.polarisation_resolved, []);
            
            
end            
