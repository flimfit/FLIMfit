function res = is_OME_tif(filename)


    res = false;

    if isempty(filename)
        errordlg('bad input');
        return;
    end;                   
    
    s = [];
    try    
        tT = Tiff(filename);
        s = tT.getTag('ImageDescription');
    catch
        return;
    end
    if isempty(s), return; end;    
    
%     detached_metadata_xml_filename = [tempdir 'metadata.xml'];     
%     fid = fopen(detached_metadata_xml_filename,'w');    
%         fwrite(fid,s,'*uint8');
%     fclose(fid);     
%     tree = xml_read(detached_metadata_xml_filename);
     [parseResult,~] = xmlreadstring(s);
     tree = xml_read(parseResult);

    try
        if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeZ'), res = true; end;
    catch err
        disp(err.message);
        return;
    end
    
%    delete(detached_metadata_xml_filename);
end
    