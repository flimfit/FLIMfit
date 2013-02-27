function [tirf,irf,name] = load_irf_file(file)

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

    if (nargin<1)
        % Get IRF data
        [tirf,irf_image_data,~,name] = open_flim_files('Select a file from the IRF data set');
    else
        [tirf,irf_image_data,~,name] = open_flim_files([],file);
    end
    
    irf_image_data = irf_image_data;
    
    % Sum over pixels
    irf = sum(sum(irf_image_data,3),2);
    
    irf = irf ./ norm(irf(:));
    
    % Pick out peak section of IRF (section of IRF within 20dB of peak)
    %[tirf,irf,background] = pickOutIRF(tirf,irf);
    
    % Remove 'background', set to minimum value of IRF
    %irf = irf - background;
    
    %scaleFactor = max(irfData)/max(irfFull);
    %plot(irfDel,irfFull.*scaleFactor,'r',irfTimes,irfData);

end