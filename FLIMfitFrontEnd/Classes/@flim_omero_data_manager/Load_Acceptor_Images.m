function Load_Acceptor_Images(obj,data_series,~)                        
                
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
    
    %{
        1) choose a dataset - current or another dataset
        2) if image names are the same, just try to load
        2) otherwise find all prefixes and choose the Acceptor prefix
        3) load images with Acceptor prefix
    %}

    if isempty(obj.dataset) 
        
            if ~isempty(obj.plate)
                %
                if isempty(data_series.n_datasets), errordlg('no images loaded, can not continue'), return, end;                 
                %
                choice = questdlg('Do you want to load Acceptor Images from current or another Plate', ' ', ...
                        'Current Plate', ...
                        'Another Plate','Cancel','Cancel');
                %
                acceptor_Plate = [];                    
                        switch choice
                            case 'Current Plate'
                                acceptor_Plate = obj.plate;
                            case 'Another Plate'
                                acceptor_Plate = select_Plate(obj.session,obj.userid,'Select Acceptor Plate:'); 
                        end 
                %
                wellList = obj.session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(acceptor_Plate.getId().getValue())],[]);
                %        
                acceptor_ids = [];
                %
                allfovnames = []; 
                %
                z = 0;
                plate_image_ids = [];                
                            for j = 0:wellList.size()-1,
                                well = wellList.get(j);
                                wellsSampleList = well.copyWellSamples();
                                well.getId().getValue();
                                for i = 0:wellsSampleList.size()-1,
                                    ws = wellsSampleList.get(i);
                                    z = z + 1;
                                    plate_image_ids(z) = ws.getImage().getId().getValue();
                                    allfovnames{z} = char(java.lang.String(ws.getImage().getName().getValue()));
                                end
                            end                    
                %
                % THIS BLOCK SELECTS NEEDED ACCEPTOR MODALITY - STARTS
                z = 0;
                modalities  = [];
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
                    [s,v] = listdlg('PromptString','Please choose Acceptor modality',...
                                                'SelectionMode','single',...
                                                'ListSize',[300 80],...                                
                                                'ListString',modalities);
                    if ~v, return, end;                    
                    acceptormodality = modalities{s};                                        
                end  
                %
                z = 0;
                for k = 1:data_series.n_datasets  
                     flim_name_k = data_series.names{k};
                        for m=1:numel(allfovnames)
                            plate_image_name_m = allfovnames{m};
                            ind_k = strfind(flim_name_k,data_series.FLIM_modality) + length(data_series.FLIM_modality);
                            ind_m = strfind(plate_image_name_m,acceptormodality) + length(acceptormodality);
                            if ~isempty(ind_m) && strcmp(flim_name_k(ind_k:length(flim_name_k)),plate_image_name_m(ind_m:length(plate_image_name_m)))
                                z = z + 1;
                                acceptor_ids(z) = plate_image_ids(m); 
                            end
                        end
                end
                %
                if data_series.n_datasets == numel(acceptor_ids)
                    if data_series.load_acceptor_images(acceptor_ids);
                        msg = 'Acceptor Images were successfully loaded';
                    else
                        msg = 'Acceptor Images were not loaded';
                    end
                    msgbox(msg);
                    return;
                end                
                %                                 
            else errordlg('Working Data was not set - can not continue'), 
                return, 
            end;
            
    else % work with dataset
    
    if isempty(data_series.n_datasets), errordlg('no images loaded, can not continue'), return, end; 
    
    choice = questdlg('Do you want to load Acceptor Images from current or another Dataset', ' ', ...
                        'Current Dataset', ...
                        'Another Dataset','Cancel','Cancel');
    %
    acceptor_dataset = [];                    
                        switch choice
                            case 'Current Dataset'
                                acceptor_dataset = obj.dataset;
                            case 'Another Dataset'
                                acceptor_dataset = select_Dataset(obj.session,obj.userid,'Select Acceptor Dataset:'); 
                        end % switch           

    if isempty(acceptor_dataset), return, end;
    %
    imageList = acceptor_dataset.linkedImageList;
    %       
    if 0==imageList.size(), errordlg('Dataset has no images - please choose a Dataset with images'); return, end;                                    
    %
    image_names = cell(1,imageList.size());
                    for k = 0:imageList.size()-1,                       
                        image_names{k+1} = char(java.lang.String(imageList.get(k).getName().getValue()));
                    end 
    image_names = sort_nat(image_names);
    %
    acceptor_ids = [];
    %
    % if FLIM and Acceptor Images have the same names - we are done!    
    for k = 1:data_series.n_datasets
        flim_name_k = data_series.names{k};
            for m = 0:imageList.size()-1,                       
                iName = char(java.lang.String(imageList.get(m).getName().getValue()));                                                                
                    if strcmp(iName,flim_name_k)
                            % it must be sigle-plane!
                            iList = getImages(obj.session,imageList.get(m).getId().getValue());
                            image = iList(1);
                            pixelsList = image.copyPixels();    
                            pixels = pixelsList.get(0);                        
                            SizeC = pixels.getSizeC().getValue();
                            SizeZ = pixels.getSizeZ().getValue();
                            SizeT = pixels.getSizeT().getValue();    
                            %
                            if ~(SizeZ~=1 || SizeC~=1 || SizeT~=1)
                                acceptor_ids = [acceptor_ids imageList.get(m).getId().getValue()];
                            end
                    end
            end                    
    end
    %
    if data_series.n_datasets == numel(acceptor_ids)
        if data_series.load_acceptor_images(acceptor_ids);
            msg = 'Acceptor Images were successfully loaded';
        else
            msg = 'Acceptor Images were not loaded';
        end
        msgbox(msg);
        return;
    end
        
    % otherwise, try to treat prefixes...    
    prefixes = [];
    for k=1:numel(image_names)
        str = split(' ',image_names{k});    
        prefixes = [prefixes str(1)];
    end
    prefixes = unique(prefixes);
    %
    acceptor_prefix = [];
    %
    if 0==numel(prefixes) 
        errordlg('acceptor prefix was not idenified, - can not continue'), return;
    elseif 1==numel(prefixes) 
        acceptor_prefix = prefixes(1); 
    else
        [s,v] = listdlg('PromptString','Please choose Acceptor prefix',...
                'SelectionMode','single',...
                'ListSize',[300 80],...                                
                'ListString',prefixes);
        %
        if ~v, return, end;
        %
        acceptor_prefix = prefixes(s);
    end

    L_acceptor_prefix = length(char(acceptor_prefix));
    for k = 1:data_series.n_datasets
        flim_name_k = data_series.names{k};
        for m = 0:imageList.size()-1,                       
            iName = char(java.lang.String(imageList.get(m).getName().getValue()));                                                                
            str = split(' ',iName);    
            prefix_m = str(1);                                                                    
            no_prefix_acceptor_name_m = iName(L_acceptor_prefix+1:length(iName));                        
                if strcmp(prefix_m,acceptor_prefix)
                    if strfind(flim_name_k,no_prefix_acceptor_name_m)
                        acceptor_ids = [acceptor_ids imageList.get(m).getId().getValue()];
                    end
                end
        end                                                
    end                    

    msg = 'Acceptor Images were not loaded';    
    if data_series.n_datasets == numel(acceptor_ids)
        if data_series.load_acceptor_images(acceptor_ids);
            msg = 'Acceptor Images were successfully loaded';
        end    
    end
    msgbox(msg);        
                  
    end

end

























