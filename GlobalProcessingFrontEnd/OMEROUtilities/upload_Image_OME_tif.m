function imageId = upload_Image_OME_tif(factory,dataset,filename,description)    

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
    