function load_tvb(obj,file)

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

    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.xml')
       
        marshal_object(file,'flim_data_series',obj);
    
    else
        
         dims = obj.get_image_dimensions(file);
        
        if isempty(dims.delays)
            return;
        end;
  
        chan_info = dims.chan_info;
       
        % Determine which channels we need to load 
        ZCT = obj.get_ZCT( dims, obj.polarisation_resolved ,chan_info);
    
        if isempty(ZCT)
            return;
        end;
        
        t_tvb = dims.delays;
        sizet = length(t_tvb);
        sizeX = dims.sizeXY(1);
        sizeY = dims.sizeXY(2);
        
        tvb_image_data = zeros(sizet, 1, sizeX, sizeY, 1);
       
        [success , tvb_image_data] = obj.load_flim_cube(tvb_image_data, file,1);
        
        tvb_image_data = squeeze(tvb_image_data);
       
        % if irf is not single pixel then reshape & average over pixels
        if (sizeX + sizeY) > 2
            tvb_data = reshape(tvb_image_data,[ sizet sizeX * sizeY ]);
            tvb = mean(tvb,2);
        else
            tvb_data = tvb_image_data;
      
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