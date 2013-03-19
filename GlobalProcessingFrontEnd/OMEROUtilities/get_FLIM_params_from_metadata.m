function ret = get_FLIM_params_from_metadata(session, image)

    
    ret = [];    
    
     s = [];
     
     objId = image.getId();
     
     
     
     pixelsList = image.copyPixels();    
     pixels = pixelsList.get(0);
            
            
     SizeC = pixels.getSizeC().getValue();
     SizeZ = pixels.getSizeZ().getValue();
     SizeT = pixels.getSizeT().getValue();
    
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
    %s = read_Annotation_having_tag(session,get_Object_by_Id(session,objId.getValue()),'ome.model.annotations.XmlAnnotation','ModuloAlong');
    
    if ~isempty(s)      % found correct ModuloAlong XmlAnnotation
        
        [parseResult,~] = xmlreadstring(s);
        tree = xml_read(parseResult);
        
             
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
            ret.delays = start:step:e;
        else
            ret.delays = cell2mat(modlo.Label);
        end
        
        if isfield(modlo.ATTRIBUTE,'Unit')
            if ~isempty(strfind(modlo.ATTRIBUTE.Unit,'NS')) || ~isempty(strfind(modlo.ATTRIBUTE.Unit,'ns'))
                ret.delays = ret.delays.* 1000;
            end
        end
        
        ret.FLIM_type = 'TCSPC';        % set as default
        
        if isfield(modlo.ATTRIBUTE,'Description')        
            ret.FLIM_type = modlo.ATTRIBUTE.Description;
        end
        
        % validity check
        % crude  test for nonsense in the Annotation
        sizet = length(ret.delays);
        switch ret.modulo
            case 'ModuloAlongZ'
                nZplanes = floor(SizeZ/sizet);
                if nZplanes * sizet ~= SizeZ
                    ret = [];   
                end
            case 'ModuloAlongC'
                nchannels = floor(SizeC/sizet);
                if nchannels * sizet ~= SizeC
                    ret = [];   
                end
            case 'ModuloAlongT'
                nTpoints = floor(SizeT/sizet);
                if nTpoints * sizet ~= SizeT
                    ret = [];   
                end
            
        end
       
        
        return;
    
    else
        % can't we just use image instead of
        % get_Object_by_Id(session,objId.getValue() ??? Ian
        s = read_Annotation_having_tag(session,image,'ome.model.annotations.FileAnnotation','bhfileHeader'); 
    end
    
    if ~isempty(s)      % found a BH file header FileAnnotation
    
        ret.modulo = 'ModuloAlongC';
        ret.FLIM_type = 'TCSPC';
        pos = strfind(s, 'bins');
        nBins = str2num(s(pos+5:pos+7));
        pos = strfind(s, 'base');
        time_base = str2num(s(pos+5:pos+14)).*1000;       % get time base & convert to ps   
        time_points = 0:nBins - 1;
        ret.delays = time_points.*(time_base/nBins);   
        return;
        
    else
        
        % no Modulo XmlAnnotation or BHFile header. Forced to treat it as a
        % LaVision ome.tif
        
             
        
        if 1 == SizeC && 1 == SizeT && SizeZ > 1
            if ~isempty(pixels.getPhysicalSizeZ().getValue())
                physSizeZ = pixels.getPhysicalSizeZ().getValue().*1000;     % assume this is in ns so convert to ps
                ret.delays = (0:SizeZ-1)*physSizeZ;
                ret.modulo = 'ModuloAlongZ';
                ret.FLIM_type = 'TCSPC';
                return;
            end
        end
                        
        
        ret = [];
        
    end
    
    
                  
             

        
    
    
  