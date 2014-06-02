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
    
    
    if obj.init  && ~isempty(obj.omero_data_manager.session)

    
        if ~isempty(obj.omero_data_manager.dataset)
            parent = obj.omero_data_manager.dataset; 
            parentType = 'omero.model.Dataset';
        elseif ~isempty(obj.omero_data_manager.plate)
            parent = obj.omero_data_manager.plate; 
            parentType = 'omero.model.Plate';
        else
            return;
        end

        parentId = java.lang.Long(parent.getId().getValue());

        % check whether an annotation of this name already exists
        session = obj.omero_data_manager.session;

        annotators = java.util.ArrayList;
        metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations(parentType, java.util.Arrays.asList(parentId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
        annotations = map.get(parentId);

        ann = [];

        if isempty(file)
            txt = strsplit(parentType,'.');
            title = char(strcat({'As an annotation to  '}, txt(end)));
            choice = questdlg('Would you like to save the current settings?', title ,'Yes','No','No');
            if strcmp(choice,'Yes')
                    pol_idx = obj.polarisation_resolved + 1;
                    file = [obj.data_settings_filename{pol_idx}];
            end
        end
        
        if ~isempty(file)
    
            tmpfile = [tempdir file ];


            if annotations.size() > 0
                for j = 0:annotations.size()-1
                    anno_name = char(java.lang.String(annotations.get(j).getFile().getName().getValue()));
                    if strcmp(anno_name, file)
                        ann = annotations.get(j);
                        break;
                    end
                end
            end


            % write data to a temp file

            if ~isempty(tmpfile)
                serialise_object(obj,tmpfile);

                % then upload this to the server
                namespace = 'IC_PHOTONICS';
                mimetype = char('application/octet-stream');

                if isempty(ann)
                    namespace = 'IC_PHOTONICS';
                    description = ' ';            
                    sha1 = char('pending');
                    file_mime_type = char('application/octet-stream');

                    add_Annotation(session, obj.omero_data_manager.userid, ...
                                parent, ...
                                sha1, ...
                                file_mime_type, ...
                                tmpfile, ...
                                description, ...
                                namespace);    

                else
                    updateFileAnnotation(session, ann, tmpfile); 

                end

            end


        end
    end
  
    
    
   
    
    
    
    
    
    
    
    
    

