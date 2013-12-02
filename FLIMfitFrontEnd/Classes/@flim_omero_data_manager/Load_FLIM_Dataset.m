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
                z = 0;
                modalities  = [];
                allfovnames = cellstr(str);
                for k=1:numel(allfovnames) % define modalities
                    curname = char(allfovnames{k});
                    startind = strfind(curname,'MODALITY = ') + length('MODALITY = ');
                    if ~isempty(startind)
                        z = z + 1;
                        s1 = split(' ',curname(startind:length(curname)));
                        modalities{z} = char(s1{1});
                    end
                end
                %
                modalities = unique(modalities,'legacy');
                if ~isempty(modalities)                                       
                    % first, run the chooser
                    [s,v] = listdlg('PromptString','Please choose FLIM modality',...
                                                'SelectionMode','single',...
                                                'ListSize',[300 80],...                                
                                                'ListString',modalities);
                    if ~v, return, end;                    
                    chosenmodality = modalities{s};                    
                    %
                    data_series.FLIM_modality = chosenmodality;
                    %
                    % then, redefine variables "str" and "imageids_unsorted"                                        
                    imageids_unsorted2 = [];
                    str2 = [];
                    z = 0;
                    for k=1:numel(imageids_unsorted)
                        if ~isempty(strfind(char(allfovnames{k}),chosenmodality))
                            z = z + 1;
                            imageids_unsorted2(z) = imageids_unsorted(k);
                            str2{z} = allfovnames{k};
                        end
                    end
                    %
                    imageids_unsorted = imageids_unsorted2;
                    folder_names_unsorted = str2;
                end                
                % THIS BLOCK SELECTS NEEDED FLIM MODALITY - ENDS
                                                                                
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
                                
                %TREAT POSSIBLE ACCEPTOR IMAGES - STARTS
                %{ 
                recognize a situation when one should load acceptor images.. 
                two possible places where to look for them - 
                1) the same Dataset, recognized by the name
                2) separate Dataset linked by the Omero tag or annotation (?)
                3) to have separate menu item (3)
                %} 
                %
                list_load_acceptor = []; % this is image names list that will be filled, possibly.. 
                %
                possible_acceptor_images = false;
                %
                prefixes = [];
                for k=1:numel(folder_names)
                    str = split(' ',folder_names{k});    
                    prefixes = [prefixes str(1)];
                end

                prefixes = unique(prefixes);

                if numel(prefixes) == 2 % check more attentively

                    p1 = char(prefixes(1));
                    p2 = char(prefixes(2));
                    if ~(strcmp(p1(1:2),'Z=') || strcmp(p1(1:2),'C=') || strcmp(p1(1:2),'T='))
                        possible_acceptor_images = true;
                    end;
                    if ~(strcmp(p2(1:2),'Z=') || strcmp(p2(1:2),'C=') || strcmp(p2(1:2),'T='))
                        possible_acceptor_images = true;
                    end;

                end
                
                if possible_acceptor_images 

                    str = { prefixes{1}...
                            prefixes{2}...
                            ['no Acceptor: load as FLIM "' prefixes{1} '" only']...
                            ['no Acceptor: load as FLIM "' prefixes{2} '" only']...
                            'load all as FLIM'};
                                [s,v] = listdlg('PromptString','Please choose posible Acceptor images',...
                                                'SelectionMode','single',...
                                                'ListSize',[300 80],...                                
                                                'ListString',str);
                                %
                                if ~v, return, end;
                                % 
                            switch s
                                case 1
                                    flim_load_prefix = prefixes{2};
                                    acceptor_load_prefix = prefixes{1};
                                case 2
                                    flim_load_prefix = prefixes{1};
                                    acceptor_load_prefix = prefixes{2};
                                case 3
                                    flim_load_prefix = prefixes{1};
                                    acceptor_load_prefix = [];
                                case 4
                                    flim_load_prefix = prefixes{2};
                                    acceptor_load_prefix = [];
                                case 5 % take them all
                                    flim_load_prefix = [];
                                    acceptor_load_prefix = [];
                            end

                    list_load_flim = [];

                    for k=1:numel(folder_names)
                        str = split(' ',folder_names{k});    
                        prefix = str(1);
                        if ~isempty(flim_load_prefix) && strcmp(prefix,flim_load_prefix)
                            list_load_flim = [list_load_flim folder_names(k)];
                        elseif ~isempty(acceptor_load_prefix) && strcmp(prefix,acceptor_load_prefix)
                            list_load_acceptor = [list_load_acceptor folder_names(k)];
                        end
                    end

                    if isempty(list_load_flim) list_load_flim = folder_names; end;

                    folder_names = list_load_flim;

                end %if possible_acceptor_images 
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
            
            %split names into components at full-stops & discard extensions                     
            for j=1:n_datasets
                strings = regexp(folder_names{j}, '\.', 'split');
                data_series.names{j} = strings{1};
            end
                           
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
            
            obj.selected_channel = data_series.ZCT(2);  % not sure what this does
            
            if data_series.polarisation_resolved & length(cell2mat(obj.selected_channel)) ~= 2
                
                errordlg('Two channels must be selected for polarization data');
                return;
            end
                        
            data_size = [ length(delays) length(cell2mat(obj.selected_channel)) mdta.sizeX mdta.sizeY ];
                       
            data_series.mode = mdta.FLIM_type;
            data_series.mdta = mdta;
                                   
            data_series.data_size = [data_size n_datasets ];
                           
                   
            if length(delays) > 0 
                
                data_series.file_names = {'file'};
                data_series.channels = data_series.ZCT{2};  % not sure what this does
                                 
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
               
                if ~isempty(list_load_acceptor)
                    %
                    acceptor_ids = [];
                    
                    % one needs to find for every loaded image ITS acceptor image                    
                    L_flim_prefix = length(flim_load_prefix);
                    for k = 1:n_datasets
                        flim_name_k = data_series.names{k};
                        no_prefix_flim_name_k = flim_name_k(L_flim_prefix+1:length(flim_name_k));                        
                            for m = 0:imageList.size()-1,                       
                                iName = char(java.lang.String(imageList.get(m).getName().getValue()));                                                                
                                    str = split(' ',iName);    
                                    prefix_m = str(1);                                                                                                
                                if strfind(iName,no_prefix_flim_name_k)
                                    if strcmp(prefix_m,acceptor_load_prefix)
                                        acceptor_ids = [acceptor_ids imageList.get(m).getId().getValue()];
                                    end
                                end
                            end                                                
                    end                    
                    %                    
                    data_series.load_acceptor_images(acceptor_ids);                     
                    %
                end               
               
                data_series.compute_tr_data(false);    
               
                                
                data_series.init_dataset();            
                
            end % if length(delays) > 0            
end            
