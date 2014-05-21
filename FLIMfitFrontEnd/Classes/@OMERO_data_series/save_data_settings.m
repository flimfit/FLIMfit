 function file = save_data_settings(obj,file)


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
    
    if nargin < 2
        file = [];
    end
    
    if ~isempty(obj.omero_data_manager.dataset)
        parent = obj.omero_data_manager.dataset;    
    elseif ~isempty(obj.plate)
        parent = obj.omero_data_manager.plate;    
    else
        return;
    end

    % write data to a temp file
    if obj.init
        if isempty(file)
            pol_idx = obj.polarisation_resolved + 1;
            file = [tempdir obj.data_settings_filename{pol_idx}];
            fname = [obj.data_settings_filename{pol_idx}];
        end
        
        if ~isempty(file)
            serialise_object(obj,file);
            
            % then upload this to the server
            namespace = 'IC_PHOTONICS';
            description = ' ';
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            
            add_Annotation(obj.session, obj.userid, ...
                parent, ...
                sha1, ...
                file_mime_type, ...
                fname, ...
                description, ...
                namespace);
            
        end
        
        
    end
    
  
    
    
   
    
    
    
    
    
    
    
    
    

