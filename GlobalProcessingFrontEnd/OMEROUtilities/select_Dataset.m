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
            alldatasetsList = proxy.loadContainerHierarchy('omero.model.Dataset', [], param);
            %                        
            did = zeros(1,alldatasetsList.size());            
                for i = 0:alldatasetsList.size()-1,
                    d = alldatasetsList.get(i);
                    dName = char(java.lang.String(d.getName().getValue()));                    
                    pName = 'NO PROJECT!';
                        for j = 0:projectsList.size()-1,
                            p = projectsList.get(j);
                                datasetsList = p.linkedDatasetList;
                                for m = 0:datasetsList.size()-1,
                                    pd = datasetsList.get(m);
                                    if pd.getId().getValue() == d.getId().getValue()
                                        pName = char(java.lang.String(p.getName().getValue()));
                                        break;
                                    end;
                                end;                            
                        end;            
                    dnme = [ pName ' @ ' dName ];
                    str(i+1,1:length(dnme)) = dnme;
                    did(i+1) = java.lang.Long(d.getId().getValue());                    
                end
            
            % request a Dataset using the "str" list
            [s,v] = listdlg('PromptString',prompt,...
                            'SelectionMode','single',...
                            'ListSize',[300 300],...
                            'ListString',str);            
            if(v) % find Project and Dataset by pre-recorded Id's
                    for i = 0:alldatasetsList.size()-1,
                        d = alldatasetsList.get(i);
                        if java.lang.Long(d.getId().getValue()) == did(s)
                            Dataset = d;
                                for j = 0:projectsList.size()-1,
                                    p = projectsList.get(j);
                                        datasetsList = p.linkedDatasetList;
                                        for m = 0:datasetsList.size()-1,
                                            pd = datasetsList.get(m);
                                            if pd.getId().getValue() == d.getId().getValue()
                                                Project = p;
                                                break;
                                            end;
                                        end;                            
                                end; 
                        return;
                        end                    
                    end                                                            
            end;
            
            
%             % populate the list of strings "str" and corresponding project and data Ids 
%             z=0;            
%             for j = 0:projectsList.size()-1,
%                 p = projectsList.get(j);
%                 pName = char(java.lang.String(p.getName().getValue()));
%                 datasetsList = p.linkedDatasetList;
%                 for i = 0:datasetsList.size()-1,
%                     d = datasetsList.get(i);
%                     dName = char(java.lang.String(d.getName().getValue()));                    
%                     %
%                      z = z + 1;                     
%                      dnme = [ pName ' @ ' dName ];
%                      str(z,1:length(dnme)) = dnme;
%                      pid(z) = java.lang.Long(p.getId().getValue());
%                      did(z) = java.lang.Long(d.getId().getValue());
%                     %
%                 end
%             end
%             %                        
%             % request a Dataset using the "str" list
%             [s,v] = listdlg('PromptString',prompt,...
%                             'SelectionMode','single',...
%                             'ListSize',[300 300],...
%                             'ListString',str);            
%             if(v) % find Project and Dataset by pre-recorded Id's
%                 for j = 0:projectsList.size()-1,
%                     p = projectsList.get(j);                                        
%                     datasetsList = p.linkedDatasetList;
%                     for i = 0:datasetsList.size()-1,
%                         d = datasetsList.get(i);
%                         if java.lang.Long(p.getId().getValue()) == pid(s) && java.lang.Long(d.getId().getValue()) == did(s)
%                             Project = p;
%                             Dataset = d;
%                         end                    
%                      end                                        
%                 end            
%             end;

        
        end