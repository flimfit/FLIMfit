 function ZCT = get_ZCT( obj, dims, polarisation_resolved, chan_info, multiple_planes )
 
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
 
            if nargin < 3
                polarisation_resolved = false;
            end
            
            if nargin < 4
                chan_info = [];
            end
            
            % allow selection of multiple planes by default
            if nargin < 5 
                multiple_planes = true;
            end

         
            sizeZCT = dims.sizeZCT;
            sizeZ = sizeZCT(1);            
            sizeC = sizeZCT(2);  
            sizeT = sizeZCT(3);  
            sizet = length(dims.delays);
            
            ZCT{1} = 1;
            ZCT{2} = 1;
            ZCT{3} = 1;
            
            if ~isempty(dims.modulo)                
                switch dims.modulo
                    case 'ModuloAlongZ'
                        sizeZ = sizeZ/sizet;                 
                    case 'ModuloAlongC'
                        sizeC = sizeC/sizet;                                       
                    case 'ModuloAlongT'
                        sizeT = sizeT/sizet;
                end
            end 
            
             
            
           if (sizeZ + sizeC + sizeT) > 3
                    
                minn = [ 1 1 1 ];   % select one from each 
                    
                if length(obj.file_names) == 1   && multiple_planes      % single file in data set
                    maxx = [ sizeZ sizeC sizeT ];       % so allow any selection
                else
                    maxx = minn;
                end
                
                
                
                ZCT = ZCT_selection([sizeZ sizeC sizeT], maxx, minn, polarisation_resolved, chan_info);
            end
            
           
          
end

