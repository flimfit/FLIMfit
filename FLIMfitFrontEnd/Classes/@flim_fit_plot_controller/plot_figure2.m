function [fig,im_data,lims] = plot_figure2(obj,dataset,im,merge,options,indexing)

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


    f = obj.fit_controller;
    r = f.fit_result;
    if isempty(f.fit_result) || (~isempty(f.fit_result.binned) && f.fit_result.binned == 1)
        return
    end
    im_data = f.get_image(dataset,im,indexing);
        
    invert = f.invert_colormap;
        
    param = r.params{im};
    
    if contains(param,' I') || strcmp(param,'I') 
        cscale = @gray;
    elseif invert && (contains(param,'tau') || contains(param,'theta'))
        cscale = @inv_jet;
    else
        cscale = @jet;
    end
    
    lims = f.get_cur_lims(im);
    options.int_lim = f.get_cur_intensity_lims(im);
    options.cscale = cscale;
    options.show_colormap = f.show_colormap;
    options.show_limits = f.show_limits;
    
    if merge
        intensity = f.get_intensity(dataset,im,indexing);
        fig = display_flim(im_data,isnan(im_data),lims,intensity,options);
    else
        fig = display_flim(im_data,isnan(im_data),lims,options);
    end

end