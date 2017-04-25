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

     prof = get_profile();    
   
     if strcmp(class(file_or_image),'char')
        file = file_or_image;
     else
        file = char(file_or_image.getName().getValue());
     end
    
     [path,name,ext] = fileparts_inc_OME(file);
        
    if strcmp(ext,'.xml')
        if isa(file_or_image,'omero.model.OriginalFileI')
            obj.marshal_object(file, file_or_image);
        else
            obj.marshal_object(file);
        end
    else
        
        [dims,reader_settings] = obj.get_image_dimensions(file_or_image);
        
        if isempty(dims.delays) 
            return;
        end
        
        if obj.polarisation_resolved
            if dims.sizeZCT(2) < 2
                errordlg('IRF must have at least 2 channels!');
                return;
            end
        end
  
        chan_info = dims.chan_info;
       
        % Determine which channels we need to load (param 4 disallows the
        % selection of multiple planes )
        ZCT = obj.get_ZCT( dims, obj.polarisation_resolved, chan_info, false);
    
        if isempty(ZCT)
            return;
        end;


        if nargin < 3
            load_as_image = false;
        end
        
        t_irf = dims.delays;
        sizet = length(t_irf);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        
        if obj.polarisation_resolved
            n_chan = 2;
        else
            n_chan = 1;
        end
        
        irf_image_data = zeros(sizet, n_chan, sizeX, sizeY, 1);
        [~ , irf_image_data] = obj.load_flim_cube(irf_image_data, file_or_image, 1, 1, reader_settings, dims, ZCT);
        irf = reshape(irf_image_data,[sizet n_chan sizeX * sizeY]);
        irf = mean(irf,3);
         

        % export may be in ns not ps.
        if max(t_irf) < 300
           t_irf = t_irf * 1000; 
        end

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


        
    end

    obj.t_irf_min = min(obj.t_irf);
    obj.t_irf_max = max(obj.t_irf);
    
    if prof.Data.Automatically_Estimate_IRF_Background && ~strcmp(ext,'.xml')
        % Don't estimate background when we load from xml - should be correct!
        obj.estimate_irf_background();
    end
    
    obj.compute_tr_irf();
    obj.compute_tr_data();
    
    notify(obj,'data_updated');

    
end
