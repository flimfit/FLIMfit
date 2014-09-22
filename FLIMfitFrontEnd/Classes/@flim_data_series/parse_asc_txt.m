function[im_data, delays] = parse_asc_txt(obj, file)

% Reads the header from a single-pixel .txt  or .csv file

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

    dataUnShaped = dlmread(file);
    siz = size(dataUnShaped);
             
    % 1d or 2d data
    if length(siz) == 2      % if  data is 2D  not 3d
        if siz(2) < 3  % transpose data from column to row if it's x by 1 or x by 2
            dataUnShaped = dataUnShaped';
            siz = size(dataUnShaped);
        end
        
        if siz(1) == 2
            
            % check if 1 is the delays
            if max(dataUnShaped(1,:)) == dataUnShaped(1,end)
                delays = squeeze(dataUnShaped(1,:));
                im_data = squeeze(dataUnShaped(2,:));   % discard delays
            else
                delays = squeeze(dataUnShaped(2,:));
                im_data = squeeze(dataUnShaped(1,:));
            end
            nbins = length(im_data);
            im_data = reshape(im_data,nbins,1,1);     
        end
        
        % 1d data
        if siz(2) == 1 | siz(1) == 1
            
            % if up to 1024 data points then assume a single-point
            % decay & 12.5ns
            
            if length(dataUnShaped) <  1025
                nbins = length(dataUnShaped);
                im_data = reshape(dataUnShaped,nbins,1,1);
                delays = (0:nbins-1)*12500.0/nbins;
            else
                % too long for a single-point decay so assume a square
                % image res by res & assume 64 time bins ???
                res = sqrt(length(dataUnShaped)/64);
                im_data = reshape(dataUnShaped, 64, res, res);
                delays = (0:63)*12500.0/64;
            end
        end
        
    else 
        im_data = [];
        delays = [];
        
    end
    
