function load_single(obj,images,polarisation_resolved)
    %> Load one or more images
    % NB The name 'load_single' is retained for compatibilty with the
    % corresponding function on flim_data_series where (currently) only a
    % single file can be opened
    
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

    % Author : Sean Warren
   
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        data_setting_file = [];
    end
    if nargin < 5
        channel = [];
    end
    
    image = images(1);
    imageID = image.getId.getValue;
    
    session = obj.omero_data_manager.session;
    
    pname = ' ';
    dname = ' ';
    
    service = session.getQueryService();
    list = service.findAllByQuery(['select l from DatasetImageLink as l where l.child.id = ', num2str(imageID)], []);
    if (list.size > 0)
        dataset = list.get(0).getParent();
        dataset = getDatasets(session, dataset.getId().getValue());
        obj.omero_data_manager.setDataset(dataset);
        dname = char(dataset.getName.getValue());
        obj.datasetId = dataset.getId().getValue();
        list = service.findAllByQuery(['select l from ProjectDatasetLink as l where l.child.id = ', num2str(dataset.getId.getValue())], []);
        if (list.size > 0)
            project = list.get(0).getParent();
            project = getProjects(session, project.getId().getValue());
            obj.omero_data_manager.project = project;
            pname = char(project.getName.getValue() );
        end
    end
    
    
    if length(images) == 1 
        obj.header_text = [ pname ' ' dname ' ' char(images(1).getName.getValue())];
        obj.n_datasets = 1;
    else
        obj.header_text = [ pname ' ' dname];
        obj.n_datasets = length(images);
    end
        
    
    if is64
        obj.use_memory_mapping = false;
    end
    
  
    obj.polarisation_resolved = polarisation_resolved;
    
    
    
    for i = 1:obj.n_datasets
        image = images(i);
        obj.file_names{i} = image;
        file = char(image.getName.getValue());
        [path,name,ext] = fileparts_inc_OME(file);
        names{i} = name;
    end
    
    
    
    obj.lazy_loading = false;
    
    if isempty(obj.names)
        obj.names = names;
    end
    
   
    
    obj.load_multiple(polarisation_resolved, data_setting_file);
    
  
end