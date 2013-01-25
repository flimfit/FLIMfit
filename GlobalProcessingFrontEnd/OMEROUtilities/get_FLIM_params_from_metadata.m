function ret = get_FLIM_params_from_metadata(session,objId)

    ret.delays = [];
    ret.numeric_delays = [];    
    ret.FLIM_type = [];
    ret.modulo = [];
    ret.n_channels = [];
    ret.SizeZ = [];
    ret.SizeC = [];
    ret.SizeT = [];

    s1 = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'ome.model.annotations.FileAnnotation','StructuredAnnotations');
    s2 = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'ome.model.annotations.FileAnnotation','bhfileHeader');
    s3 = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'ome.model.annotations.FileAnnotation','Imspector Pro ');
    s4 = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'ome.model.annotations.XmlAnnotation','ModuloAlong');

    if          ~isempty(s1) % xml file annotation
            s = s1;
        elseif  ~isempty(s2) % B&H - image
            s = s2;            
        elseif  ~isempty(s3) % LaVision            
            s = s3;            
        elseif  ~isempty(s4) % xml annotated - image      
            s = s4;            
    end

    if isempty(s2) && ( ~isempty(s1) || ~isempty(s3) || ~isempty(s4) )
        detached_metadata_xml_filename = [tempdir 'metadata.xml'];
        fid = fopen(detached_metadata_xml_filename,'w');    
            fwrite(fid,s,'*uint8');
        fclose(fid);
        tree = xml_read(detached_metadata_xml_filename);
    end;    

    if ~isempty(s2) || ~isempty(s4) % will need image in this case..
            image = get_Object_by_Id(session,objId.getValue());
            pixelsList = image.copyPixels();    
            pixels = pixelsList.get(0);
            ret.SizeZ = pixels.getSizeZ().getValue(); 
            ret.SizeC = pixels.getSizeC().getValue(); 
            ret.SizeT = pixels.getSizeT().getValue();                         
    end;    
        
    % MAIN METADATA ASSIGNMENT PART
    if          ~isempty(s1) % file annotation

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            if isfield(tree.Image,'HRI'), ret.FLIM_type = 'Gated'; end;
            if isfield(tree.Image,'FLIMType'), ret.FLIM_type = tree.Image.FLIMType; end;

            if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeC')     
                ret.SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
                ret.SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
                ret.SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;               
            end    
            %           

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
                    
                        ret.n_channels = ret.SizeT/numel(ret.delays);

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

                        ret.n_channels = ret.SizeC/numel(ret.delays);

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

                        ret.n_channels = ret.SizeZ/numel(ret.delays);

                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Unit')
                        if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Unit,'ns')
                            ret.delays = ret.delays*1000; % assumes units are ps  unless specified as ns
                        end
                    end

                end
            end        
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        elseif  ~isempty(s2) % B&H - image
            
            ret.modulo = 'ModuloAlongC';
            ret.FLIM_type = 'TCSPC';
                pos = strfind(s, 'bins');
                nBins = str2num(s(pos+5:pos+7));
                    pos = strfind(s, 'base');
                    time_base = str2num(s(pos+5:pos+14)).*1000;        % get time base & convert to ps   
            time_points = 0:nBins - 1;
            ret.numeric_delays = time_points.*(time_base/nBins);   
            ret.n_channels = ret.SizeC/nBins;
                        
        elseif  ~isempty(s3) % LaVision            

            if isfield(tree,'Image') && isfield(tree.Image,'ca_COLON_CustomAttributes')
                software_name = tree.Image.ca_COLON_CustomAttributes.ImspectorVersion.ATTRIBUTE.ImspectorVersion;
                if strfind(software_name,'Imspector Pro ')
                    ret.SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
                    ret.SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
                    ret.SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;            
                    ret.FLIM_type = 'TCSPC';
                    ret.modulo = 'ModuloAlongZ';
                    incr = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ*1000;
                    %ret.delays = num2cell((0:ret.SizeZ-1)*incr);
                    ret.numeric_delays = (0:ret.SizeZ-1)*incr;
                    ret.n_channels = 1;
                end

            end;
                        
        elseif  ~isempty(s4) % xml annotated - image      

            ret.FLIM_type = 'TCSPC';
            
            modlo = [];
            if isfield(tree,'ModuloAlongC')
                modlo = tree.ModuloAlongC;
                ret.modulo = 'ModuloAlongC';
                SizeM = pixels.getSizeC().getValue();
                ret.SizeC = SizeM;                
            elseif isfield(tree,'ModuloAlongT')
                modlo = tree.ModuloAlongT;
                ret.modulo = 'ModuloAlongT';
                SizeM = pixels.getSizeT().getValue();
                ret.SizeT = SizeM;                
            elseif  isfield(tree,'ModuloAlongZ')
                modlo = tree.ModuloAlongZ;
                ret.modulo = 'ModuloAlongZ';
                SizeM = pixels.getSizeZ().getValue();
                ret.SizeZ = SizeM;                
            end;   
                if isfield(modlo.ATTRIBUTE,'Start')
                    start = modlo.ATTRIBUTE.Start;
                    step = modlo.ATTRIBUTE.Step;
                    e = modlo.ATTRIBUTE.End;                
                    ret.numeric_delays = start:step:e;
                else
                    ret.delays = modlo.Label;
                end

            ret.n_channels = SizeM/numel(ret.numeric_delays);
            
    else % all are empty but let us treat it as Z LaVision file

        if strcmp('Image',whos_Object(session,objId.getValue()))
        
            image = get_Object_by_Id(session,objId.getValue());
            pixelsList = image.copyPixels();    
            pixels = pixelsList.get(0);
            ret.SizeZ = pixels.getSizeZ().getValue(); 
            ret.SizeC = pixels.getSizeC().getValue(); 
            ret.SizeT = pixels.getSizeT().getValue();                         
            %
            ret.modulo = 'ModuloAlongZ';
            ret.FLIM_type = 'TCSPC';
            ret.n_channels = 1;
              
            physSizeZ = pixels.getPhysicalSizeZ().getValue().*1000;     % assume this is in ns so convert to ps
            ret.numeric_delays = (0:ret.SizeZ-1)*physSizeZ;
                       
        end
                
    end
            
    if isempty(ret.delays)
        dels = cell(1,numel(ret.numeric_delays));
        for k=1:numel(dels), dels{k} = ret.numeric_delays(k); end
        ret.delays = dels;                                                                
    end;

    if isempty(ret.numeric_delays)
        %
        % TODO
        %
    end;
    
end
