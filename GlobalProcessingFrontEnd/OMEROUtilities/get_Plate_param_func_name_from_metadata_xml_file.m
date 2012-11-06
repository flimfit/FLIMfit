function func_name = get_Plate_param_func_name_from_metadata_xml_file(filename)

    func_name = [];
    try
        tree = xml_read(filename);    
        if isfield(tree,'PlateParametersFunctionName')
            func_name = tree.PlateParametersFunctionName;
        end
    catch e
        rethrow(e);
    end

% PHOTPlateXMLmetadata.PlateParametersFunctionName = 'parse_WP_format1'; 
% xmlFileName = 'plate_reader_metadata.xml';
% xml_write(xmlFileName,PHOTPlateXMLmetadata);

