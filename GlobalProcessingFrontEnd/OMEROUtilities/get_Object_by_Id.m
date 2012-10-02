        function obj = get_Object_by_Id(session,objId)
            %
            obj = [];            
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
                    obj = p;
                    return;
                end;
                datasetsList = p.linkedDatasetList;
                for i = 0:datasetsList.size()-1,                     
                     d = datasetsList.get(i);
                     did = java.lang.Long(d.getId().getValue());
                     if did == objId
                        obj = d;
                        return;
                     end
                     imageList = d.linkedImageList;
                     for k = 0:imageList.size()-1,                       
                         img = imageList.get(k);
                         iid = java.lang.Long(img.getId().getValue());
                         if iid == objId
                            obj = img;
                            return;
                         end                         
                     end 
                end;
            end;                                    
        end