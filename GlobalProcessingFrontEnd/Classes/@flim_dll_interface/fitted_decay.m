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
    
    
    n_fit = sum(mask(:)>0);
    n_t = length(t);
    n_chan = d.n_chan;
    
    p_fit = libpointer('doublePtr',zeros([n_t n_chan n_fit]));
    p_n_valid = libpointer('int32Ptr',0);
    try
        
        calllib(obj.lib_name,'FLIMGlobalGetFit', obj.dll_id, im, n_t, t, n_fit, loc, p_fit, p_n_valid);
        
        n_valid = p_n_valid.Value;
        decay = p_fit.Value;
        decay = reshape(decay,[n_t n_chan n_fit]);
        
        decay = nansum(decay,3);
        decay = decay / double(n_valid);
       
        
    catch error
        
        decay = zeros(n_t,1);
         disp('Warning: Could not get fit');
    end
            
    clear p_fit;
    

end