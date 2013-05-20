function im_data = plot_figure(obj,h,hc,dataset,im,merge,text,indexing)

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
    intensity = f.get_intensity(dataset,indexing);
    im_data = f.get_image(dataset,im,indexing);
    
    %im_data = stdfilt(im_data);
    
    invert = f.invert_colormap;
        
    param = r.params{im};
    
    if strcmp(param,'I0') || strcmp(param,'I')
        cscale = @gray;
    elseif invert && (~isempty(strfind(param,'tau')) || ~isempty(strfind(param,'theta')))
        cscale = @inv_jet;
    else
        cscale = @jet;
    end
    
    lims = f.get_cur_lims(im);
    I_lims = f.get_cur_intensity_lims();
    
    if ~merge
        colorbar_flush(h,hc,im_data,isnan(intensity),lims,cscale,text);
    else
        colorbar_flush(h,hc,im_data,[],lims,cscale,text,intensity,I_lims);
    end

end