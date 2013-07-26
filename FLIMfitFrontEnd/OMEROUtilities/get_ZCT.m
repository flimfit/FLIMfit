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
            
             
            
            if polarisation_resolved == true
                
                
                
                if (Z + T) > 2
                    maxx = [ 1  1];   % select one from each 
                    minn = maxx;      % no subset selection allowed
            
                    ZT = ZT_selection([Z T], maxx, minn);
                    dims{1} = ZT{1};
                    dims{3} = ZT{2}
                     
                end
                
                if C  > 1
                    
                    chans = -1;
                    
                    while max(chans) > C  | chans == -1
                     
                        % copied from request_channels in flim_data_series
                        dlgTitle = 'Select channels';
                        prompt = {'Parallel Channel';'Perpendicular Channel'};
                        defaultvalues = {'1','2'};
                        numLines = 1;
                        inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                        chans = str2double(inputdata);
                    end
                    
                    dims{2} = chans;

                end
                
                
            else
            
                if (Z + C + T) > 3
                
                    maxx = [ 1 1 1];   % select one from each 
                    minn = maxx;      % no subset selection allowed
            
                    dims = ZCT_selection([Z C T], maxx, minn);
                end
            
            end
          
end

