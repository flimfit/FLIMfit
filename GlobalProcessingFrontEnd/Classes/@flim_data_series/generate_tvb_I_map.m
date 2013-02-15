function bg_data = generate_tvb_I_map(obj, mask, dataset)

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

    decay = obj.get_roi(mask, dataset);
    decay = mean(decay,3);
    decay(decay<0) = 0;
    n = 4;
    nt = 5;
        
    Idecay = repmat(decay,[1 1 obj.height obj.width]);
    
    I = obj.cur_tr_data ./ Idecay;
    I = squeeze(mean(mean(I,1),2));
    
    f=figure('Units','Pixels');
    p = get(f,'Position');
    p(2:4) = [200,400,600];
    set(f,'Position',p);
    
    subplot(2,1,1);
    plot(obj.tr_t,decay);
    
    subplot(2,1,2);
    imagesc(I);
    daspect([1,1,1]);
    colorbar
    
    bg_data = struct('t_bg',obj.tr_t,'tvb_profile',decay,'tvb_I_image',I,'background_value',obj.background_value);
    

    
    
    
end