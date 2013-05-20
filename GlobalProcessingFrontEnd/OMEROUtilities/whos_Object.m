function obj_type = whos_Object(session, objId)
            %
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
                    
            obj_type = 'unknown';            
            %
            param = omero.sys.ParametersI();            
            param.leaves();            
            
                                        
            myprojects = getProjects(session ,objId);
            if ~isempty(myprojects) 
                obj_type = 'Project';
                return;
            end
            
            mydatasets = getDatasets(session ,objId);
            if ~isempty(mydatasets) 
                obj_type = 'Dataset';
                return;
            end
            
            myimages = getImages(session,objId);
            if ~isempty(myimages) 
                obj_type = 'Image';
                return;
            end
                        
            iQuery = session.getQueryService();
                    screenList = iQuery.findAllByQuery('select this from Screen this left outer join fetch this.plateLinks links left outer join fetch links.child plates', param);                                
                    for k = 0:screenList.size()-1,                       
                         scr = screenList.get(k);
                         scrid = java.lang.Long(scr.getId().getValue());
                         if scrid == objId
                            obj_type = 'Screen';
                            return;
                         end  
                         platesList = scr.linkedPlateList;
                         for m = 0:platesList.size()-1,                       
                             plt = platesList.get(m);
                             pltid = java.lang.Long(plt.getId().getValue());
                             if pltid == objId
                                obj_type = 'Plate';
                                return;
                             end  
                         end;
                    end;
end

                