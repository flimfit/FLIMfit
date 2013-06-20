 function ret = select_Project(session,userId,prompt)
 
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
        

            if isempty(userId)
                userId = session.getAdminService().getEventContext().userId;
            end;     

            ret = [];
                        % one needs to choose Project where to store new data
                        proxy = session.getContainerService();
                        %Set the options
                        param = omero.sys.ParametersI();
                        param.noLeaves();
                        %
                        param.exp(omero.rtypes.rlong(userId));
                        projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
                        % populate the list of strings "str"                                    
                        z=0;
                        str = char(256,256);
                        for j = 0:projectsList.size()-1,
                            p = projectsList.get(j);
                            pName = char(java.lang.String(p.getName().getValue()));
                                 z = z + 1;
                                 str(z,1:length(pName)) = pName;
                        end
                        str = str(1:projectsList.size(),:);
                        % request
                        [s,v] = listdlg('PromptString',prompt,...
                                        'SelectionMode','single',...
                                        'ListSize',[300 300],...                                        
                                        'ListString',str);                        
                        if(v) % here it is
                            ret = projectsList.get(s-1);
                        else
                            return;
                        end;                                            
        end
