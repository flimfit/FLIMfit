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
    
    cur = obj.cur_tr_data;
    mask = obj.mask;
    
    % Solve linear least squares problem
    I = sum(sum(cur.*Idecay,1),2) ./ sum(sum(Idecay.*Idecay,1),2);
    I = squeeze(I);    
        
    sz = size(Idecay);
    sz(3:4) = 1;
    
    dI = obj.cur_tr_data - repmat(reshape(I,[1 1 size(I)]),sz) .* Idecay;
    dI = squeeze(sum(sum(dI.*dI,1),2));
    
    dIuncorrected = obj.cur_tr_data- mean(I(:)) .* Idecay;
    dIuncorrected = squeeze(sum(sum(dIuncorrected.*dIuncorrected,1),2));
    
    dI(~mask) = NaN;
    dIuncorrected(~mask) = NaN;
    
    sum(dI(:))
    
    f=figure('Units','Pixels');
    p = get(f,'Position');
    p(2:4) = [200,600,300];
    set(f,'Position',p);
    
    subplot(2,2,1);
    plot(obj.tr_t,decay);
    title('TVB Profile');
    
    subplot(2,2,2);
    imagesc(I);
    daspect([1,1,1]);
    colorbar
    title('TVB Intensity Scale Factor')
    
    subplot(2,2,3);
    imagesc(dI);
    daspect([1,1,1]);
    colorbar
    caxis([0 2e5]);
    title('Corrected Residual')

    
    subplot(2,2,4);
    imagesc(dIuncorrected);
    daspect([1,1,1]);
    colorbar
    caxis([0 2e5]);
    title('Uncorrected Residual')
    bg_data = struct('t_bg',obj.tr_t,'tvb_profile',decay,'tvb_I_image',I,'background_value',obj.background_value);
    

    

    
    
    
end