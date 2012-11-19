function [ FLIM_type delays modulo n_channels ] = get_FLIM_params_from_metadata(session,objId,annotation_filename)


    delays = [];
    FLIM_type = [];
    modulo = [];
    n_channels = [];

    s = read_Annotation(session,get_Object_by_Id(session,objId.getValue()),annotation_filename);
    if isempty(s), return, end;

    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
    
    try
        [ FLIM_type delays modulo n_channels ] = get_FLIM_params_from_metadta_xml_file(detached_metadata_xml_filename);
    catch
    end

end
