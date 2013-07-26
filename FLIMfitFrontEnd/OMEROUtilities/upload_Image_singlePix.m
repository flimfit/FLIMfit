function upload_Image_singlePix(session, dataset, full_filename, modulo_in)

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
      
modulo = modulo_in;
if strcmp(modulo_in,'ModuloAlongC') modulo = 'ModuloAlongZ'; end; % hack

    [delays,im_data,~] = load_flim_file(lower(full_filename),1);
    pixeltype = get_num_type(im_data);

    str = split(filesep,full_filename);
    fname = char(str(numel(str)));
    imgId = mat2omeroImage(session, im_data, pixeltype, fname,'',[],modulo);   

    link = omero.model.DatasetImageLinkI;
    link.setChild(omero.model.ImageI(imgId, false));
    link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
    session.getUpdateService().saveAndReturnObject(link);
      
% annotation
                                                          
    % non-FLIM  
    if delays(1) > 250 % spectrum..
        
        if delays(1) > 250000 % hack
            delays = delays/1000;
        end
        
        node = com.mathworks.xml.XMLUtils.createDocument('Modulo');
        Modulo = node.getDocumentElement;     
            namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';    
            Modulo.setAttribute('namespace',namespace);        
        ModuloAlong = node.createElement(modulo);
        ModuloAlong.setAttribute('Type','wavelength');
        ModuloAlong.setAttribute('Unit','nm');
        ModuloAlong.setAttribute('TypeDescription','Spectrum');
        ModuloAlong.setAttribute('Start',num2str(delays(1)));
            step = (delays(end) - delays(1))./(length(delays) -1);
        ModuloAlong.setAttribute('Step',num2str(step));
        ModuloAlong.setAttribute('End',num2str(delays(end)));
        Modulo.appendChild(ModuloAlong);
    else % FLIM
        node = create_ModuloAlongDOM(delays, [], modulo, 'TCSPC');
    end
            
    id = java.util.ArrayList();
    id.add(java.lang.Long(imgId)); %id of the image
    containerService = session.getContainerService();
    list = containerService.getImages('Image', id, omero.sys.ParametersI());
    image = list.get(0);
    % 
    add_XmlAnnotation(session,[],image,node);
% annotation
