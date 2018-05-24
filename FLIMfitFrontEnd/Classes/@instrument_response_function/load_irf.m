function load_irf(obj,file_or_image,load_as_image)

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

    obj.is_init = false;
    
     prof = get_profile();    
   
     if ischar(file_or_image)
        file = file_or_image;
     else
        file = char(file_or_image.getName().getValue());
     end
    
     [~,~,ext] = fileparts_inc_OME(file);
        
    if strcmp(ext,'.xml')
       
        if isa(file_or_image,'omero.model.OriginalFileI')
            obj.marshal_object(file, file_or_image);
        else
            doc_node = xmlread(file);
            obj = marshal_object(doc_node,'instrument_response_function',obj);
        end
    
    elseif strcmp(ext, '.json')
        
        json_data = fileread(file);
        params = jsondecode(json_data);
        
        obj.is_analytical = true;
        obj.gaussian_parameters = params;
        obj.n_chan = length(params);
        
    else
        
        reader = get_flim_reader(file_or_image);
                
        if isempty(reader.delays) 
            return;
        end
        
        if obj.polarisation_resolved
            if reader.sizeZCT(2) < 2
                errordlg('IRF must have at least 2 channels!');
                return;
            end
        end
      
        options.expected_channels = obj.n_chan;
        options.allow_multiple_images = false;
        [z,c,t,channels] = zct_selection_dialog(reader.sizeZCT,reader.chan_info,options);
        
        if nargin < 3
            load_as_image = false;
        end
        
        t_irf = reader.delays;
        sizet = length(t_irf);
        sizeX = reader.sizeXY(1);
        sizeY = reader.sizeXY(2);
        
        irf_image_data = reader.read([z c t],channels);
        irf = reshape(irf_image_data,[sizet obj.n_chan sizeX * sizeY]);
        irf = mean(irf,3);
         
        % sort in time order
        t_irf = t_irf(:);
        [t_irf, sort_idx] = sort(t_irf);
        irf = irf(sort_idx,:);
        irf_image_data = irf_image_data(sort_idx,:,:,:);

        if load_as_image
            irf_image_data = obj.smooth_flim_data(irf_image_data,7);
            obj.image_irf = irf_image_data;
            obj.has_image_irf = true;
        else
            obj.has_image_irf = false;
        end
        
        obj.t_irf = t_irf;
        obj.irf = irf;
        obj.irf_name = 'irf';
        obj.is_analytical = false;

        
    end

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    if prof.Data.Automatically_Estimate_IRF_Background && ~strcmp(ext,'.xml')
        % Don't estimate background when we load from xml - should be correct!
        obj.estimate_irf_background();
    end
    
    obj.init();
    
end
