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

    if 0 == data_series.n_datasets, errordlg('no images loaded'), return, end; 
    
    choice = questdlg('Do you want to load Acceptor Images from current or another Dataset', ' ', ...
                        'Current Dataset', ...
                        'Another Dataset','Cancel','Cancel');
    %
    acceptor_dataset = [];                    
                        switch choice
                            case 'Current Dataset'
                                if ~isempty(obj.dataset)
                                    acceptor_dataset = obj.dataset;
                                end;
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
    % if FLIM and Acceptor Images have the same names - we are do ne!    
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
            message = 'Acceptor Images were successfully loaded';
        else
            message = 'Acceptor Images were not loaded';
        end
        msgbox(message);
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

    if data_series.n_datasets == numel(acceptor_ids) && data_series.load_acceptor_images(acceptor_ids)
            message = 'Acceptor Images were successfully loaded';
        else
            message = 'Acceptor Images were not loaded';
    end
    msgbox(message);
              
end

























