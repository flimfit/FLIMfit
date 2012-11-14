        function ret = select_Screen(session,prompt)
            ret = [];
                        % one needs to choose Project where to store new data
                        proxy = session.getContainerService();
                        %Set the options
                        param = omero.sys.ParametersI();
                        userId = session.getAdminService().getEventContext().userId; %id of the user.
                        param.exp(omero.rtypes.rlong(userId));
                        screenList = proxy.loadContainerHierarchy('omero.model.Screen', [], param);
                        % populate the list of strings "str"                                    
                        z=0;
                        str = char(256,256);
                        for j = 0:screenList.size()-1,
                            p = screenList.get(j);
                            pName = char(java.lang.String(p.getName().getValue()));
                                 z = z + 1;
                                 str(z,1:length(pName)) = pName;
                        end
                        str = str(1:screenList.size(),:);
                        % request
                        [s,v] = listdlg('PromptString',prompt,...
                                        'SelectionMode','single',...
                                        'ListString',str);                        
                        if(v) % here it is
                            ret = screenList.get(s-1);
                        else
                            return;
                        end;                                            
        end
