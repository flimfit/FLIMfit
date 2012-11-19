        function [ Plate Screen ] = select_Plate(session,prompt)
        
            %
            Plate = [];
            Screen = [];            
            %
            proxy = session.getContainerService();
            %Set the options
            param = omero.sys.ParametersI();
            userId = session.getAdminService().getEventContext().userId; %id of the user.
            param.exp(omero.rtypes.rlong(userId));
            screensList = proxy.loadContainerHierarchy('omero.model.Screen', [], param);
            %
            % populate the list of strings "str" and corresponding project and data Ids 
            z=0;            
            for j = 0:screensList.size()-1,
                p = screensList.get(j);
                pName = char(java.lang.String(p.getName().getValue()));
                platesList = p.linkedPlateList;
                for i = 0:platesList.size()-1,
                    d = platesList.get(i);
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
                for j = 0:screensList.size()-1,
                    p = screensList.get(j);                                        
                    platesList = p.linkedPlateList;
                    for i = 0:platesList.size()-1,
                        d = platesList.get(i);
                        if java.lang.Long(p.getId().getValue()) == pid(s) && java.lang.Long(d.getId().getValue()) == did(s)
                            Screen = p;
                            Plate = d;
                        end                    
                     end                                        
                end            
            end;
        end