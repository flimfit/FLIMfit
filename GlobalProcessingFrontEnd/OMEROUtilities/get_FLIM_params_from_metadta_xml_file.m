function ret = get_FLIM_params_from_metadta_xml_file(filename)

    ret.delays = [];
    ret.FLIM_type = [];
    ret.modulo = [];
    ret.n_channels = 1;
    ret.SizeZ = [];
    ret.SizeC = [];
    ret.SizeT = [];
            
    tree = xml_read(filename);
     
    if isempty(tree), return, end;
                    
    %LaVision kludge    
    if isfield(tree,'Image') && isfield(tree.Image,'ca_COLON_CustomAttributes')
        software_name = tree.Image.ca_COLON_CustomAttributes.ImspectorVersion.ATTRIBUTE.ImspectorVersion;
        if strfind(software_name,'Imspector Pro ')
            ret.SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
            ret.SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
            ret.SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;            
            ret.FLIM_type = 'TCSPC';
            ret.modulo = 'ModuloAlongZ';
            incr = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ*1000;
            ret.delays = num2cell((0:ret.SizeZ-1)*incr);
            ret.n_channels = 1;
        end
        return;
    end;

    ret.FLIM_type = 'TCSPC'; % default
    
    if ~isfield(tree,'Image') % the possibility that modulo is attached xml annotation
        modlo = [];
        if isfield(tree,'ModuloAlongC')
            modlo = tree.ModuloAlongC;
            ret.modulo = 'ModuloAlongC';
        elseif isfield(tree,'ModuloAlongT')
            modlo = tree.ModuloAlongT;
            ret.modulo = 'ModuloAlongT';
        elseif  isfield(tree,'ModuloAlongZ')
            modlo = tree.ModuloAlongZ;
            ret.modulo = 'ModuloAlongZ';
        end;   
        
            if isfield(modlo.ATTRIBUTE,'Start')
                start = modlo.ATTRIBUTE.Start;
                step = modlo.ATTRIBUTE.Step;
                e = modlo.ATTRIBUTE.End;                
                     lifetimes = start:step:e;
                     dels = cell(1,numel(lifetimes));
                     for k=1:numel(lifetimes), dels{k} = lifetimes(k); end
                     ret.delays = dels;                                                                
            else
                ret.delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.Label;
            end
            
        ret.n_channels = [];     
        return;
         
    end
    
    
    
        if isfield(tree.Image,'HRI'), ret.FLIM_type = 'Gated'; end;
        if isfield(tree.Image,'FLIMType'), ret.FLIM_type = tree.Image.FLIMType; end;

        if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeC')     
            ret.SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
            ret.SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
            ret.SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;               
        end    
        %           
        ret.n_channels = ret.SizeC; % # FLIM blocks

        if isfield(tree,'SA_COLON_StructuredAnnotations') 

            if  isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongT') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Type)

                ret.modulo = 'ModuloAlongT';
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Start')
                    start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Start;
                    step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Step;
                    e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.End;                
                         lifetimes = start:step:e;
                         dels = cell(1,numel(lifetimes));
                         for k=1:numel(lifetimes), dels{k} = lifetimes(k); end
                         ret.delays = dels;                                                                
                else
                    ret.delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.Label;
                end
                if ret.SizeT >= numel(ret.delays) && 1 == ret.n_channels %
                    ret.n_channels = ret.SizeT/numel(ret.delays);
                end
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Unit')
                    if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Unit,'ns')
                        ret.delays = ret.delays*1000; % assumes units are ps  unless specified as ns
                    end
                end

            elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongC') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Type)

                ret.modulo = 'ModuloAlongC';
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Start')
                    start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Start;
                    step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Step;
                    e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.End;                
                         lifetimes = start:step:e;
                         dels = cell(1,numel(lifetimes));
                         for k=1:numel(lifetimes), dels{k} = lifetimes(k); end
                         ret.delays = dels;                                                                
                else
                    ret.delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.Label;
                end
                if ret.SizeC >= numel(ret.delays) 
                    ret.n_channels = ret.SizeC/numel(ret.delays);
                end
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Unit')
                    if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit,'ns')
                        ret.delays = ret.delays*1000; % assumes units are ps  unless specified as ns
                    end
                end

            elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongZ') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Type)     

                ret.modulo = 'ModuloAlongZ';
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Start')
                    start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Start;
                    step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Step;
                    e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.End;                
                         lifetimes = start:step:e;
                         dels = cell(1,numel(lifetimes));
                         for k=1:numel(lifetimes), dels{k} = lifetimes(k); end                     
                         ret.delays = dels;                                                                
                else
                    ret.delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.Label;
                end
                if ret.SizeZ >= numel(ret.delays) && 1 == ret.n_channels
                    ret.n_channels = ret.SizeZ/numel(ret.delays);
                end
                if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Unit')
                    if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Unit,'ns')
                        ret.delays = ret.delays*1000; % assumes units are ps  unless specified as ns
                    end
                end

            end
        end        
    
end
    
    