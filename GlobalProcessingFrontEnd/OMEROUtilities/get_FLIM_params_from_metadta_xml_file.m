function ret = get_FLIM_params_from_metadta_xml_file(filename)

    ret.delays = [];
    ret.FLIM_type = [];
    ret.modulo = [];
    ret.n_channels = 1;
    ret.SizeZ = [];
    ret.SizeC = [];
    ret.SizeT = [];
            
    tree = xml_read(filename);
                
    if isfield(tree.Image,'HRI'), ret.FLIM_type = 'Gated'; end;
    if isfield(tree.Image,'FLIMType'), ret.FLIM_type = tree.Image.FLIMType; end;
    
    if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeC')     
        ret.SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
        ret.SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
        ret.SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;       
    end
        
    if isfield(tree,'StructuredAnnotation') 
        if     isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongT')
            ret.delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.Label;
            ret.modulo = 'ModuloAlongT';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE,'NumberOfFLIMChannels')
                ret.n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongT.ATTRIBUTE.NumberOfFLIMChannels;
            end;            
        elseif isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongC')
            ret.delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.Label;
            ret.modulo = 'ModuloAlongC';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE,'NumberOfFLIMChannels')
                ret.n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.NumberOfFLIMChannels;
            end;
        elseif isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo,'ModuloAlongZ')
            ret.delays = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.Label;        
            ret.modulo = 'ModuloAlongZ';
            if isfield(tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE,'NumberOfFLIMChannels')
                ret.n_channels = tree.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongZ.ATTRIBUTE.NumberOfFLIMChannels;
            end;            
        end
    end
    %
    %LaVision kludge    
    if isfield(tree.Image,'ca_COLON_CustomAttributes')
        software_name = tree.Image.ca_COLON_CustomAttributes.ImspectorVersion.ATTRIBUTE.ImspectorVersion;
        if strcmp(software_name,'Imspector Pro ')
            SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
            ret.FLIM_type = 'TCSPC';
            ret.modulo = 'ModuloAlongZ';
            incr = 12500/SizeZ; %ps ??
            ret.delays = num2cell((0:SizeZ-1)*incr);
        end
    end;
    
    