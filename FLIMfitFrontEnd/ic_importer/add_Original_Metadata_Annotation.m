function add_Original_Metadata_Annotation(session,userId,image,full_filename)

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
    
            if isempty(userId)
                userId = session.getAdminService().getEventContext().userId;
            end;     

        bfdata = bfopen(full_filename);
        metadata = bfdata{1, 2}; % place for original metadata :)         
        if isempty(metadata), return, end;
        if 0==metadata.size(), return, end;
        %
            detached_metadata_filename = [tempdir 'original_metadata.txt'];
            fid = fopen(detached_metadata_filename,'w');    
            %
                metadataKeys = metadata.keySet().iterator();
                for i=1:metadata.size()
                    key = metadataKeys.nextElement();
                    value = metadata.get(key);
                    if isnumeric(value)
                        if value == floor(value)
                            format = '%s=%d\r\n';
                        else
                            format = '%s=%e\r\n';
                        end
                    else
                        format = '%s=%s\r\n';
                    end
                    fprintf(fid,format, key, value);
                end                                    
            fclose(fid);                
        namespace = 'ORIGINAL_METADATA_NS';        
        description = ' ';        
        sha1 = char('pending');
        file_mime_type = char('application/octet-stream');        
        add_Annotation(session, userId, ...
                        image, ...
                        sha1, ...
                        file_mime_type, ...
                        detached_metadata_filename, ...
                        description, ...
                        namespace);            
                    
end

