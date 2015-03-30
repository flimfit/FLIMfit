function load_plate(obj, file)   
    %> Load images from an ome.tiff containing a plate with full SPW
    % annotation
    
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
    
    
    [path,name,ext] = fileparts_inc_OME(file);
    
    if ~strcmp(ext,'.ome')
        errordlg('Not an ome.tiff - please choose an ome.tiff containing plate data');
        return;
    end
    
   
    root_path = ensure_trailing_slash(path);
    
    obj.header_text = root_path;

    obj.root_path = root_path;
    
    obj.polarisation_resolved = polarisation_resolved;
    obj.header_text = root_path;
    
    % Get the channel filler
    r = loci.formats.ChannelFiller();
    r = loci.formats.ChannelSeparator(r);
    
    OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
    r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());
    
   
    r.setId(file);
   
    seriesCount = r.getSeriesCount;
    
    %r.setSeries(i - 1);
    omeMeta = r.getMetadataStore();
    
    if omeMeta.getPlateCount == 0 || seriesCount == 0
            errordlg('Error: File does not contain plate data!');
        return;
    end
        
    image_names{1,seriesCount} = [];        % pre-allocate
    for i = 1:seriesCount
        image_names{i} = [name ext '.tiff [' char(omeMeta.getImageName(i -1)) ']'];
    end
    
    [selected_names, ~, obj.lazy_loading] = dataset_selection(image_names);
    
    n_datasets = length(selected_names);
    
    
    if n_datasets == 0
        return;
    end
    
   
    obj.n_datasets = n_datasets;
    obj.names = selected_names;
    
   
    
    metadata = struct();
    
    
    % assume only one plate & find matching Row and Column
    cols = omeMeta.getPlateColumns(0).getValue;
    rows = omeMeta.getPlateColumns(0).getValue;
    
    imageSeries = ones(1,n_datasets);       % pre-allocate
    file_names{1,n_datasets} = [];      
    
    for i=1:n_datasets
        file_names{i} = file;     % same file name for each image
        sel = selected_names{i};
        for j = 1:length(image_names)
            if strcmp(sel,image_names{j})
                imageSeries(i) = j;
                r.setSeries(j - 1);
                imageID = omeMeta.getImageID(j -1);
                % now find matching wellsample in order to set metadata
                for well = 0:(rows*cols) - 1
                    for sample = 0:omeMeta.getWellSampleCount(0,well)-1
                        wellSampleID = omeMeta.getWellSampleImageRef(0,well,sample);
                        if strcmp(wellSampleID,imageID);
                            row = char(omeMeta.getWellRow(0,well).getValue() + 'A');
                            % NB add 1 as FLIMfit plate columns start at 0
                            col = num2str(omeMeta.getWellColumn(0,well).getValue() + 1);
                            add_class('Well');
                            add_class('Row');
                            add_class('Column');
                
                            metadata.Well{i} = [row col];
                            metadata.Row{i} = row;
                            metadata.Column{i} = col;
                            metadata.FileName{i} = sel;
                            break;
                        end
                    end
                end
            end
        end
    end
    
    obj.file_names = file_names;
    
    names = fieldnames(metadata);

    for j=1:length(names)

        d =  metadata.(names{j});
       
        try
            nums = cellfun(@str2num,d,'UniformOutput',true);
            metadata.(names{j}) = num2cell(nums);  
        catch 
            metadata.(names{j}) = d;  
        end
    end
    
    obj.metadata = metadata;
    
    
    obj.imageSeries = imageSeries;
    
    obj.load_multiple(polarisation_resolved, []);
    
    function add_class(class)
        if ~isfield(metadata,class)
            metadata.(class) = cell(1,n_datasets);
        end
    end
    
end
    
    
    
   
     