function [param_data, mask] = get_image(obj,dataset,param,indexing)

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


    param_data = 0;
    mask = 0;
        
    if nargin < 4 || strcmp(indexing,'result')
        dataset = obj.datasets(dataset);
    end
    
    if (obj.bin || param == 0)
        return
    end
            
    sz = obj.im_size;
    
    
    p_mask = libpointer('uint16Ptr', NaN(sz));
    p_param_data = libpointer('singlePtr', NaN(sz));

    err = calllib(obj.lib_name,'GetParameterImage',obj.dll_id, dataset-1, param-1, p_mask, p_param_data);
    
    mask = p_mask.Value;
    mask = reshape(mask, sz);
    
    param_data = p_param_data.Value;
    param_data = reshape(param_data, sz);

end