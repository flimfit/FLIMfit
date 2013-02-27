 function ret = create_new_Dataset(session,project,new_dataset_name,description)
         
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
        
            ret = [];
            %
            newdataset = omero.model.DatasetI;              
            newdataset.setName(omero.rtypes.rstring(char(new_dataset_name)));
            newdataset.setDescription(omero.rtypes.rstring(char(description)));
            %link Dataset and Project
            if ~isempty(project)
                link = omero.model.ProjectDatasetLinkI;
                link.setChild(newdataset);            
                link.setParent(omero.model.ProjectI(project.getId().getValue(),false));
                session.getUpdateService().saveAndReturnObject(link);
                % find newly created dataset by name
                proxy = session.getContainerService();
                param = omero.sys.ParametersI();
                param.noLeaves(); %no images loaded, this is the default value.
                userId = session.getAdminService().getEventContext().userId;
                param.exp(omero.rtypes.rlong(userId));            
                projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);            
                % there is no check of existing dataset name - the same name
                % might appear many times..
                for j = 0:projectsList.size()-1,
                    p = projectsList.get(j);                
                    datasetsList = p.linkedDatasetList;
                    for i = 0:datasetsList.size()-1,
                        d = datasetsList.get(i);
                        dName = char(java.lang.String(d.getName().getValue()));                                        
                        % 
                        if strcmp(new_dataset_name,dName) && java.lang.Long(p.getId().getValue()) == java.lang.Long(project.getId().getValue())
                            ret = d;
                            break;
                        end;                    
                    end;
                end;                                                                                
                %                                
            else
                ret = session.getUpdateService().saveAndReturnObject(newdataset);                                                
            end;
            
        end  