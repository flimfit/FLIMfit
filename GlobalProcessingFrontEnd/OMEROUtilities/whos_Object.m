function obj_type = whos_Object(session,objId)
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
            end;
            datasetsList = proxy.loadContainerHierarchy('omero.model.Dataset', [], param);
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
                         end;
                     end;
                end;
            %
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
                         for k = 0:platesList.size()-1,                       
                             plt = platesList.get(k);
                             pltid = java.lang.Long(plt.getId().getValue());
                             if pltid == objId
                                obj_type = 'Plate';
                                return;
                             end  
                             %
                            wellList = session.getQueryService().findAllByQuery(['select well from Well as well '...
                            'left outer join fetch well.plate as pt '...
                            'left outer join fetch well.wellSamples as ws '...
                            'left outer join fetch ws.plateAcquisition as pa '...
                            'left outer join fetch ws.image as img '...
                            'left outer join fetch img.pixels as pix '...
                            'left outer join fetch pix.pixelsType as pt '...
                            'where well.plate.id = ', num2str(plt.getId().getValue())],[]);
                            for j = 0:wellList.size()-1,
                                well = wellList.get(j);
                                wellsSampleList = well.copyWellSamples();
                                well.getId().getValue();
                                for i = 0:wellsSampleList.size()-1,
                                    ws = wellsSampleList.get(i);
                                    ws.getId().getValue();
                                    % pa = ws.getPlateAcquisition();
                                    iid = java.lang.Long(ws.getImage().getId().getValue());
                                    if iid == objId
                                       obj_type = 'Image';
                                       return;
                                    end;
                                end;
                            end;
                         end;
                    end;
end

                