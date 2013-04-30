function [ Plate Screen ] = select_Plate(session,prompt)

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
            % sort by Screen etc. - start
            strcell_sorted = sort_nat(cellstr(str));
            strcell_unsorted = cellstr(str);
            did_sorted = zeros(1,screensList.size()); % to fill..
            %
            for d = 1:numel(strcell_sorted)
                for dd = 1:numel(strcell_sorted)
                    if strcmp(char(strcell_sorted(d)),char(strcell_unsorted(dd)))
                        did_sorted(d) = did(dd);
                        break;
                    end
                end
            end
            str = char(strcell_sorted);
            did = did_sorted;    
                                    
            % request a Dataset using the "str" list
            [s,v] = listdlg('PromptString',prompt,...
                            'SelectionMode','single',...
                            'ListSize',[300 300],...                            
                            'ListString',str);            
            if(v) % find Project and Dataset by pre-recorded Id's
                for j = 0:screensList.size()-1,
                    p = screensList.get(j);                                        
                    platesList = p.linkedPlateList;
                    for i = 0:platesList.size()-1,
                        d = platesList.get(i);
                        if java.lang.Long(d.getId().getValue()) == did(s)
                            Screen = p;
                            Plate = d;
                            return;
                        end                    
                     end                                        
                end            
            end
end
        

                