function ret = get_FLIM_params_from_metadata(session,objId)

    ret.delays = [];
    ret.FLIM_type = [];
    ret.modulo = [];
    ret.n_channels = [];
    ret.SizeZ = [];
    ret.SizeC = [];
    ret.SizeT = [];

    s = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'StructuredAnnotations');
    
    if isempty(s) % temp
        s = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'DimensionOrder');
    end;
        
    if isempty(s), return, end;

    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
    
    try
        ret_ = get_FLIM_params_from_metadta_xml_file(detached_metadata_xml_filename);
        ret = ret_;
    catch err
        [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);                
    end

end
