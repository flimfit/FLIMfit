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