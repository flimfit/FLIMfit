function save_raw_data(obj, folder)

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
    
    if obj.use_popup
        wait_handle=waitbar(0,'Saving OME tiff...');
    end
    
    folder = ensure_trailing_slash(folder);
    
    
    % Setup metadata
    data = permute_to_OME(obj.cur_data);
    metadata = createMinimalOMEXMLMetadata(data);

    modlo = loci.formats.CoreMetadata();

    modlo.moduloT.type = loci.formats.FormatTools.LIFETIME;
    modlo.moduloT.unit = 'ps';

    if strcmp(obj.mode, 'TCSPC')
        modlo.moduloT.typeDescription = 'TCSPC';
    else
        modlo.moduloT.typeDescription = 'Gated';
    end
    
    modlo.moduloT.labels = javaArray('java.lang.String',length(obj.t));
    for i=1:length(obj.t)
        modlo.moduloT.labels(i)= java.lang.String(num2str(obj.t(i)));
    end

    OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
    OMEXMLService.addModuloAlong(metadata,modlo,0);

    
    
    obj.suspend_transformation(true);
    
    for j=1:obj.n_datasets
       
        obj.switch_active_dataset(j);
        data = obj.cur_data;
        if isempty(data) || size(data,1) ~= obj.n_t
            data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
        end

        data = permute_to_OME(data);
        
        if obj.use_popup
            waitbar(j/obj.n_datasets,wait_handle)
        end

        filename = [folder obj.names{j} '.OME.tiff'];
        
        bfsave(data, filename, 'metadata', metadata);

        
    end

    obj.suspend_transformation(false);
                
    if obj.use_popup
        close(wait_handle)
    end
    
    function data = permute_to_OME(data)
        % Permute to correct OME order, add dummy z dimension
        data = permute(data,[4 3 2 1]);
        sz = size(data);
        data = reshape(data,[sz(1:2) 1 sz(3:4)]);
 
    end
        
end
