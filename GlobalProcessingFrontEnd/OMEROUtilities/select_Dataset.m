        function [ Dataset Project ] = select_Dataset(session,prompt)
            %
            Dataset = [];
            Project = [];            
            %
            proxy = session.getContainerService();
            %Set the options
            param = omero.sys.ParametersI();
            %param.noLeaves(); %no images loaded, this is the default value.
            param.leaves();
            userId = session.getAdminService().getEventContext().userId; %id of the user.
            param.exp(omero.rtypes.rlong(userId));
            projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
            %
            % populate the list of strings "str" and corresponding project and data Ids 
            z=0;            
            for j = 0:projectsList.size()-1,
                p = projectsList.get(j);
                pName = char(java.lang.String(p.getName().getValue()));
                datasetsList = p.linkedDatasetList;
                for i = 0:datasetsList.size()-1,
                    d = datasetsList.get(i);
                    dName = char(java.lang.String(d.getName().getValue()));                    
                    %
                     z = z + 1;                     
                     dnme = [ pName '@' dName ];
                     str(z,1:length(dnme)) = dnme;
                     pid(z) = java.lang.Long(p.getId().getValue());
                     did(z) = java.lang.Long(d.getId().getValue());
                    %
                end
            end
            %                        
            % request a Dataset using the "str" list
            [s,v] = listdlg('PromptString',prompt,...
                            'SelectionMode','single',...
                            'ListString',str);            
            if(v) % find Project and Dataset by pre-recorded Id's
                for j = 0:projectsList.size()-1,
                    p = projectsList.get(j);                                        
                    datasetsList = p.linkedDatasetList;
                    for i = 0:datasetsList.size()-1,
                        d = datasetsList.get(i);
                        if java.lang.Long(p.getId().getValue()) == pid(s) && java.lang.Long(d.getId().getValue()) == did(s)
                            Project = p;
                            Dataset = d;
                        end                    
                     end                                        
                end            
            end;
        end