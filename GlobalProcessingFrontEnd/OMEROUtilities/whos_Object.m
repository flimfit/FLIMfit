        function obj_type = whos_Object(session,objId)
            %
            obj_type = 'unknown';            
            %
            proxy = session.getContainerService();
            %Set the options
            param = omero.sys.ParametersI();
            %
            param.leaves();
            %
            userId = session.getAdminService().getEventContext().userId; %id of the user.
            param.exp(omero.rtypes.rlong(userId));
            projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
            %
            for j = 0:projectsList.size()-1,
                p = projectsList.get(j);
                pid = java.lang.Long(p.getId().getValue());                
                if pid == objId
                    obj_type = 'Project';
                    return;
                end;
                datasetsList = p.linkedDatasetList;
                for i = 0:datasetsList.size()-1,                     
                     d = datasetsList.get(i);
                     did = java.lang.Long(d.getId().getValue());
                     if did == objId
                        obj_type = 'Dataset';
                        return;
                     end
                     imageList = d.linkedImageList;
                     for k = 0:imageList.size()-1,                       
                         img = imageList.get(k);
                         iid = java.lang.Long(img.getId().getValue());
                         if iid == objId
                            obj_type = 'Image';
                            return;
                         end                         
                     end 
                end;
            end;                                    
        end