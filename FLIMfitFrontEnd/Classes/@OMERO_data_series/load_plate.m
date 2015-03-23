function load_plate(obj,omero_plate)
    %> Load one or more images from a plate
   
    % Copyright (C) 2015 Imperial College London.
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

    
    polarisation_resolved = false;
    
    session = obj.omero_data_manager.session;
    
    selected_images = [];
    
    pId = omero_plate.getId().getValue();
    
    wellList = session.getQueryService().findAllByQuery(['select well from Well as well '...
        'left outer join fetch well.plate as pt '...
        'left outer join fetch well.wellSamples as ws '...
        'left outer join fetch ws.plateAcquisition as pa '...
        'left outer join fetch ws.image as img '...
        'left outer join fetch img.pixels as pix '...
        'left outer join fetch pix.pixelsType as pt '...
        'where well.plate.id = ', num2str(pId)],[]);
    z = 0;
    for j = 0:wellList.size()-1,
        well = wellList.get(j);
        wellsSampleList = well.copyWellSamples();
        well.getId().getValue();
        for i = 0:wellsSampleList.size()-1,
            ws = wellsSampleList.get(i);
            ws.getId().getValue();
            z = z + 1;
            image = ws.getImage();
            imageList(z) = image;
        end
    end
    
    if isempty(imageList) | length(imageList) == 0
        errordlg('Plate has no images - please choose a Plate with images');
        return;
    end;
    
    for k = 1:length(imageList)
         image_names{k} = char(imageList(k).getName().getValue());
    end
    
    image_names = sort_nat(image_names);
    
    [image_names, ~, obj.lazy_loading] = dataset_selection(image_names);
    
    n_datasets = length(image_names);
    
    
    if n_datasets == 0
        return;
    end
   
    
    session = obj.omero_data_manager.session;
    
    sname = ' ';
    pname = char(omero_plate.getName.getValue());
    
    service = session.getQueryService();
    
    list = service.findAllByQuery(['select l from ScreenPlateLink as l where l.child.id = ', num2str(pId)], []);
    if (list.size > 0)
        screen = list.get(0).getParent();
        screen = getScreens(session, screen.getId().getValue());
        obj.omero_data_manager.screen = screen;
        sname = char(screen.getName.getValue() );
    end
    
 
    obj.header_text = [ sname ' ' pname];
    obj.n_datasets = n_datasets;
    obj.plateId = pId;
    obj.omero_data_manager.plate = omero_plate;
    obj.polarisation_resolved = polarisation_resolved;
 
    metadata = struct();
   
    % find corresponding Image list...
    for m = 1:n_datasets
        name = image_names{m};
        obj.names{m} = name;
        % now search through all the wells looking for this name
        for j = 0:wellList.size()-1,
            well = wellList.get(j);
            row = char(well.getRow().getValue() + 'A');
            col = num2str(well.getColumn().getValue());
            wellsSampleList = well.copyWellSamples();
            for i = 0:wellsSampleList.size()-1,
                ws = wellsSampleList.get(i);
                wsname = ws.getImage.getName.getValue();
                if strcmp(name,wsname)
                    selected_image = ws.getImage;
                    selected_images{m} = selected_image;
                    add_class('Well');
                    add_class('Row');
                    add_class('Column');
                    metadata.Well{m} = [row col];
                    metadata.Row{m} = row;
                    metadata.Column{m} = col;
                    metadata.FileName{m} = name;
                    break;
                end
            end
        end
    end
    
    
    names = fieldnames(metadata);

    for j=1:length(names)

        d =  metadata.(names{j});
       
        try
            nums = cellfun(@str2num,d,'UniformOutput',true);
            metadata.(names{j}) = num2cell(nums);  
        catch %#ok
            metadata.(names{j}) = d;  
        end
    end
    
    obj.metadata = metadata;
    
    obj.file_names = selected_images;

    obj.load_multiple(polarisation_resolved, []);
    
    function add_class(class)
        if ~isfield(metadata,class)
            metadata.(class) = cell(1,n_datasets);
        end
    end


end
   
    