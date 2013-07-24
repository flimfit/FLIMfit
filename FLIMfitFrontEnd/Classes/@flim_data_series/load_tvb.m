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

        if strcmp(obj.mode,'TCSPC')
            channel = obj.request_channels(obj.polarisation_resolved);
        else
            channel = 1;
        end

        [t_tvb,tvb_data] = load_flim_file(file,channel);    
        tvb_data = double(tvb_data);

        % Sum over pixels
        s = size(tvb_data);
        if length(s) == 3
            tvb_data = reshape(tvb_data,[s(1) s(2)*s(3)]);
            tvb_data = mean(tvb_data,2);
        elseif length(s) == 4
            tvb_data = reshape(tvb_data,[s(1) s(2) s(3)*s(4)]);
            tvb_data = mean(tvb_data,3);
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