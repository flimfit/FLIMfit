function load_tvb(obj,file_or_image)

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
    
    if strcmp(class(file_or_image),'char')
        file = file_or_image;
    else
        file = char(file_or_image.getName().getValue());
    end
    
    
    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xml')
       
        marshal_object(file,'flim_data_series',obj);
    
    else
        
         dims = obj.get_image_dimensions(file_or_image);
        
        if isempty(dims.delays)
            return;
        end;
  
        chan_info = dims.chan_info;
       
        % Determine which channels we need to load (param 5 disallows the
        % selection of multiple planes )
        ZCT = obj.get_ZCT( dims, obj.polarisation_resolved ,chan_info, false);
    
        if isempty(ZCT)
            return;
        end;
        
        t_tvb = dims.delays;
        sizet = length(t_tvb);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        
        if obj.polarisation_resolved
            tvb_image_data = zeros(sizet, 2, sizeX, sizeY, 1);
            [success , tvb_image_data] = obj.load_flim_cube(tvb_image_data, file_or_image,1);
            tvb_data = reshape(tvb_image_data,[sizet 2 sizeX * sizeY]);
            tvb_data = mean(tvb_data,3);
        else
            tvb_image_data = zeros(sizet, 1, sizeX, sizeY, 1);
            [success , tvb_image_data] = obj.load_flim_cube(tvb_image_data, file_or_image,1);
            tvb_data = reshape(tvb_image_data,[sizet  sizeX * sizeY]);
            tvb_data = mean(tvb_data,2);
        end
       
        
      

        % export may be in ns not ps.
        if max(t_tvb) < 300
           t_tvb = t_tvb * 1000; 
        end

        tvb = zeros(size(obj.t))';
        % check we have all timepoints
        %if length(t_tvb)~=length(obj.t)
            for i=1:length(t_tvb)
                tvb(abs(obj.t-t_tvb(i))<0.1) = tvb_data(i);
            end
            tvb_data = tvb;

            %warning('GlobalProcessing:ErrorLoadingTVB','Timepoints were different in TVB and data');
        %end

        obj.tvb_profile = tvb_data;
    end
    
    obj.compute_tr_tvb_profile();
    
    notify(obj,'data_updated');

    
end