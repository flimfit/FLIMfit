 function dims = get_ZCT( image, modulo, sizet, polarisation_resolved )
 
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
 
            if nargin < 4
                polarisation_resolved = false;
            end

          pixelsList = image.copyPixels();    
                pixels = pixelsList.get(0);
            %
            Z = pixels.getSizeZ().getValue();            
            C = pixels.getSizeC().getValue();
            T = pixels.getSizeT().getValue();
            %
            dims{1} = 1;
            dims{2} = 1;
            dims{3} = 1;
            
            if ~isempty(modulo)                
                switch modulo
                    case 'ModuloAlongZ'
                        Z = Z/sizet;                 
                    case 'ModuloAlongC'
                        C = C/sizet;                                       
                    case 'ModuloAlongT'
                        T = T/sizet;
                end
            end 
            
            
            
            maxx = [  1 1 1]; % choose a single plane by default
            
            
            if polarisation_resolved == true
                maxx(2) = 2;     % 2 channels needed for polarization
            end
            
            minn = maxx;      % no subset selection allowed
            
            
            if (Z + C + T) > 3
                dims = ZCT_selection([Z C T], maxx, minn);
            end
            
          
end

