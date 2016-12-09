function decay = fitted_decay(obj,t,im_mask,selected)


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


    d = obj.data_series;
    p = obj.fit_params;
        
    decay = [];
        
    if (p.split_fit || p.global_variable > 0) && ~obj.bin
        return
    end
    
    if ~d.use(selected)
        return
    end
    
    im = selected-1;
    
    if obj.bin
        mask = 1;
        im = 0;
    else
        mask = im_mask;
    end
    
    mask = mask(:);
    loc = 0:(length(mask)-1);
    loc = loc(mask);
    loc = uint32(loc);
    
    [decay, n_valid] = ff_Controller(obj.dll_id, 'GetFit', im, loc);
    
    if (all(isnan(decay)))
        decay = NaN(n_t,n_chan);
    else
        decay = nansum(decay,3);
        decay = decay / double(n_valid);
    end
           
end