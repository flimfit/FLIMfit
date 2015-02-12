
function load_data_series(obj,omero_dataset,mode,polarisation_resolved,data_setting_file,selected,channel)   
    % Load a series of images from an OMERO dataset

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
                          
    if nargin < 7
        channel = [];
    end
    if nargin < 6
        selected = [];
    end
    if nargin < 5
        data_setting_file = [];
    end
    
    session = obj.omero_data_manager.session;
    
    
    selected_images = [];
    
    imageList = getImages(session, 'dataset', omero_dataset.getId().getValue());
    
    if 0==imageList.size()
        errordlg('Dataset has no images - please choose a Dataset with images');
        return;
    end;
    
    for k = 1:length(imageList)
        image_names{k} = char(imageList(k).getName().getValue());
    end
    
    image_names = sort_nat(image_names);
    
    if isempty(selected)
        [image_names, ~, obj.lazy_loading] = dataset_selection(image_names);
    elseif strcmp(selected,'all')
        obj.lazy_loading = false;
    else
        image_names = image_names(selected);
        obj.lazy_loading = false;
    end
    
   
    n_datasets = length(image_names);
    
    
    if n_datasets == 0
        return;
    end
   
    
    session = obj.omero_data_manager.session;
    
    pname = ' ';
    dname = char(omero_dataset.getName.getValue());
    
    service = session.getQueryService();
    
    list = service.findAllByQuery(['select l from ProjectDatasetLink as l where l.child.id = ', num2str(omero_dataset.getId.getValue())], []);
    if (list.size > 0)
        project = list.get(0).getParent();
        project = getProjects(session, project.getId().getValue());
        obj.omero_data_manager.project = project;
        pname = char(project.getName.getValue() );
    end
    
 
    obj.header_text = [ pname ' ' dname];
    obj.n_datasets = n_datasets;
 
   
    % find corresponding Image list...
    for m = 1:n_datasets
        iName_m = image_names{m};
        [~,name,~] = fileparts_inc_OME(iName_m);
        obj.names{m} = name;
        for k = 1:length(imageList)
            iName_k = char(imageList(k).getName().getValue());
            if strcmp(iName_m,iName_k)
                selected_images{m} = imageList(k);
                break;
            end;
        end
    end
    
    obj.file_names = selected_images;

    obj.load_multiple(polarisation_resolved, []);


end
