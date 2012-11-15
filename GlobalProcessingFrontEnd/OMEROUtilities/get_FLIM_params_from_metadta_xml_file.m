function [ FLIM_type delays modulo n_channels ] = get_FLIM_params_from_metadta_xml_file(filename)

    delays = [];
    FLIM_type = [];
    modulo = [];
    n_channels = 1;

    tree = xml_read(filename);
                
    if isfield(tree.Image,'HRI'), FLIM_type = 'Gated'; end;
    if isfield(tree.Image,'FLIMType'), FLIM_type = tree.Image.FLIMType; end;
    
    if isfield(tree,'StructuredAnnotation') 
        if     isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongT')
            delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.Label;
            modulo = 'ModuloAlongT';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE,'NumberOfFLIMChannels')
                n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE.NumberOfFLIMChannels;
            end;            
        elseif isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongC')
            delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.Label;
            modulo = 'ModuloAlongC';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE,'NumberOfFLIMChannels')
                n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.NumberOfFLIMChannels;
            end;
        elseif isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongZ')
            delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.Label;        
            modulo = 'ModuloAlongZ';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE,'NumberOfFLIMChannels')
                n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE.NumberOfFLIMChannels;
            end;            
        end
    end
    %
    %LaVision kludge    
    if isfield(tree.Image,'ca_COLON_CustomAttributes')
        software_name = tree.Image.ca_COLON_CustomAttributes.ImspectorVersion.ATTRIBUTE.ImspectorVersion;
        if strcmp(software_name,'Imspector Pro ')
            SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
            FLIM_type = 'TCSPC';
            modulo = 'ModuloAlongZ';
            incr = 12500/SizeZ; %ps ??
            delays = num2cell((0:SizeZ-1)*incr);
        end
    end;
