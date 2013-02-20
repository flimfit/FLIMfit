function imageId = upload_Image_OME_tif(factory,dataset,filename,description) 

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
        

    imageId = OME_tif2Omero_Image(factory,filename,description);

    if isempty(imageId) || isempty(dataset), errordlg('bad input'); return; end;                   

    tT = Tiff(filename);
    s = tT.getTag('ImageDescription');
    if isempty(s), return; end;    
    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
        
    link = omero.model.DatasetImageLinkI;
    link.setChild(omero.model.ImageI(imageId, false));
    link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
    factory.getUpdateService().saveAndReturnObject(link);

    image = get_Object_by_Id(factory,imageId.getValue());
        
    namespace = 'IC_PHOTONICS';
    description = ' ';
    %
    sha1 = char('pending');
    file_mime_type = char('application/octet-stream');
    %
    add_Annotation(factory, ...
                    image, ...
                    sha1, ...
                    file_mime_type, ...
                    detached_metadata_xml_filename, ...
                    description, ...
                    namespace);    
    %
    delete(detached_metadata_xml_filename);    
end
    