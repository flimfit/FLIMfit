function compute_tr_tvb_profile(obj)
%> Calculate the transformed time varying background profile

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


    if obj.init
       
        % Downsample
        sel = 0:(length(obj.t)-1);
        sel = mod(sel,obj.downsampling) == 0;
        tr_t = obj.tr_t_all(sel);
        
        % Crop based on limits
        t_inc = tr_t >= obj.t_min & tr_t <= obj.t_max;

        %if ~isempty(obj.tr_t_irf)
        %    t_inc = t_inc & tr_t >= min(obj.tr_t_irf);
        %end
        
        if size(obj.tvb_profile,1) ~= obj.n_t
            obj.tvb_profile = zeros(obj.n_t, obj.n_chan);
        end
        
        obj.tr_tvb_profile = double(obj.tvb_profile);
        
        sz = size(obj.tvb_profile);
        sz(1) = sz(1) / obj.downsampling;
        obj.tr_tvb_profile = reshape(obj.tr_tvb_profile,[obj.downsampling sz]);
        obj.tr_tvb_profile = nansum(obj.tr_tvb_profile,1);
        obj.tr_tvb_profile = reshape(obj.tr_tvb_profile,sz);

        % Subtract background and crop
        obj.tr_tvb_profile = obj.tr_tvb_profile(t_inc,:,:,:);

        % Scale the background based on the size of the smoothing kernel.
        % If we move away from square binning then this will need to be
        % changed. 
        %obj.tr_tvb_profile = obj.tr_tvb_profile * obj.binning^2;

            
    end
end