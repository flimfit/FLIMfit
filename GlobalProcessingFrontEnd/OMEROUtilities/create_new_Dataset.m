        function ret = create_new_Dataset(session,project,new_dataset_name,description)
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
                ret = session.getUpdateService().saveAndReturnObject(link);                                                
            else
                ret = session.getUpdateService().saveAndReturnObject(newdataset);                                                
            end;
            
        end  
        