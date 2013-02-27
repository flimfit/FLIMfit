function ZCT = get_ZCT( image, modulo )

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
        

          pixelsList = image.copyPixels();    
                pixels = pixelsList.get(0);
            %
            maxZ = pixels.getSizeZ().getValue();            
            maxC = pixels.getSizeC().getValue();
            maxT = pixels.getSizeT().getValue();
            %
            dims = {1,1,1};
            if ~isempty(modulo)                
                switch modulo
                    case 'ModuloAlongZ'
                        if ~(1==maxC && 1==maxT)
                            dims = ZCT_chooser({1,maxC,maxT});
                        end                    
                    case 'ModuloAlongC'
                        if ~(1==maxZ && 1==maxT)
                            dims = ZCT_chooser({maxZ,1,maxT});
                        end                                        
                    case 'ModuloAlongT'
                        if ~(1==maxZ && 1==maxC)
                            dims = ZCT_chooser({maxZ,maxC,1});
                        end
                end
            end            
            %
            ZCT  = cell2mat(dims);
end

