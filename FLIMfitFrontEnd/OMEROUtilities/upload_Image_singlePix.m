function upload_Image_singlePix(session, dataset, full_filename, modulo)

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
                
    [delays,im_data,~] = load_flim_file(full_filename,1);
    pixeltype = get_num_type(im_data);

    str = split(filesep,full_filename);
    fname = char(str(numel(str)));
    imgId = mat2omeroImage(session, im_data, pixeltype, fname,'',[],modulo);   

    link = omero.model.DatasetImageLinkI;
    link.setChild(omero.model.ImageI(imgId, false));
    link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
    session.getUpdateService().saveAndReturnObject(link);
      
% annotation
    node = create_ModuloAlongDOM(delays, [], modulo, 'TCSPC');
    
    id = java.util.ArrayList();
    id.add(java.lang.Long(imgId)); %id of the image
    containerService = session.getContainerService();
    list = containerService.getImages('Image', id, omero.sys.ParametersI());
    image = list.get(0);
    % 
    add_XmlAnnotation(session,[],image,node);
% annotation
