function res = is_OME_tif(filename)

    res = false;

    if isempty(filename)
        errordlg('upload_Image: bad input');
        return;
    end;                   
    
    tT = Tiff(filename);
    s = tT.getTag('ImageDescription');
    if isempty(s), return; end;    
    
    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
    
    tree = xml_read(detached_metadata_xml_filename);
                
    try
        if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeZ'), res = true; end;
    catch
    end
    
    delete(detached_metadata_xml_filename);
end
    