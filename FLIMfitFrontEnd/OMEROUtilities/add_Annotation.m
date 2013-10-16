function ret = add_Annotation(session,userId,object,sha1,file_mime_type,full_file_name,description,namespace)

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
        end
        %
        ret = false;
        %
        if isempty(full_file_name) || isempty(full_file_name) || isempty(sha1)...
                || isempty(file_mime_type) || isempty(session) || isempty(object)
            return;
        end;
        %
%    try                               

        fa = writeFileAnnotation(session, full_file_name,...
            'mimetype', file_mime_type, 'description', description,...
            'namespace', namespace);
        whos_object = whos_Object(session, object.getId().getValue());
        linkAnnotation(session, fa, lower(whos_object),...
            object.getId().getValue());
        %
%     catch ME
%         disp(ME);
%         return;
%     end
    %
    ret = true;    
end
