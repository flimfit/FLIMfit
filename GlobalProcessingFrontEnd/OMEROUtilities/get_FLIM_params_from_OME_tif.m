function [ FLIM_type delays modulo n_channels ] = get_FLIM_params_from_OME_tif(filename)

    FLIM_type = [];
    delays  = [];
    modulo = 'not set up';
    n_channels = [];
    
    if isempty(filename)
        errordlg('upload_Image: bad input');
        return;
    end;                   
    
    tT = Tiff(filename);
    s = tT.getTag('ImageDescription'); %getTag accesses “native” tiff header data (bitdepth, x/y res etc.) – OME-XML data is stored in the ImageDescription field.      
    if isempty(s), return; end;    
    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
    
    try
        ret = get_FLIM_params_from_metadta_xml_file(detached_metadata_xml_filename);
        FLIM_type   = ret.FLIM_type;
        delays      = ret.delays;
        modulo      = ret.modulo;
        n_channels  = ret.n_channels;
    catch
    end;
    
end
    