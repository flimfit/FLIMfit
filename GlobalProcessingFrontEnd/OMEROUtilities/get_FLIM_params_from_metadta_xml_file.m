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
        
    if isfield(tree,'StructuredAnnotations') 
        if     isfield(tree.StructuredAnnotations.XMLAnnotation.Value.Modulo,'ModuloAlongT')
            ret.delays = tree.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongT.Label;
            ret.modulo = 'ModuloAlongT';
            ret.n_channels = ret.SizeT/numel(ret.delays);
        elseif isfield(tree.StructuredAnnotations.XMLAnnotation.Value.Modulo,'ModuloAlongC')
            ret.delays = tree.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongC.Label;
            ret.modulo = 'ModuloAlongC';
            ret.n_channels = ret.SizeC/numel(ret.delays);            
        elseif isfield(tree.StructuredAnnotations.XMLAnnotation.Value.Modulo,'ModuloAlongZ')
            ret.delays = tree.StructuredAnnotations.XMLAnnotation.Value.Modulo.ModuloAlongZ.Label;        
            ret.modulo = 'ModuloAlongZ';
            ret.n_channels = ret.SizeZ/numel(ret.delays);                        
        end
    end
    %    
    %
    %LaVision kludge    
    if isfield(tree.Image,'ca_COLON_CustomAttributes')
        software_name = tree.Image.ca_COLON_CustomAttributes.ImspectorVersion.ATTRIBUTE.ImspectorVersion;
        if strcmp(software_name,'Imspector Pro ')
            SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
            ret.FLIM_type = 'TCSPC';
            ret.modulo = 'ModuloAlongZ';
            incr = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ*1000;
            ret.delays = num2cell((0:SizeZ-1)*incr);
        end
    end;
    
    