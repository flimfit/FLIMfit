function ret = get_FLIM_params_from_metadata(session,obj)

    ret.delays = [];
    ret.FLIM_type = [];
    ret.modulo = [];
    ret.n_channels = [];
    ret.SizeZ = [];
    ret.SizeC = [];
    ret.SizeT = [];
    
    % assumes obj is an an image 
    pixelsList = obj.copyPixels();    
    pixels = pixelsList.get(0); 
    
    
    ret.SizeZ = pixels.getSizeZ.getValue();
    ret.SizeC = pixels.getSizeC.getValue();
    ret.SizeT = pixels.getSizeT.getValue();
    
    
    % search for a 'proper' moduloAlong annotation
    [s, n_annotations]  = read_Annotation_having_tag(session,obj,'openmicroscopy.org/omero/dimension/modulo');
    
    if n_annotations == 0 % no annotations so assume LaVision ome-tif imported via (old ) insight
        
        if ret.SizeZ > 2 
              ret.modulo = 'ModuloAlongZ';
              ret.FLIM_type = 'TCSPC';
              ret.n_channels = 1;
              
              physSizeZ = pixels.getPhysicalSizeZ().getValue().*1000;    % assume this is in ns so convert to ps
              delays = 0:ret.SizeZ -1;
              ret.delays = delays .* physSizeZ; 
              
        end
        
        return;
        
    end
    
    % this  test required only for LaVision files imported via
   % ic_importer without a proper ModuloAlong annotation 
   % should be removed ASAP !!!
   %if isempty(s)
   %     s = read_Annotation_having_tag(session,obj,'ImspectorVersion');
   %end
    
    
    if ~isempty(s)  % found ModuloAlong Annotation
        detached_metadata_xml_filename = [tempdir 'metadata.xml'];
        fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
        fclose(fid);

        try
            % use metadata to fill in the rest of the ret structure
            ret = get_FLIM_params_from_metadata_xml_file(detached_metadata_xml_filename,ret);
            
        catch err
            [ST,~] = dbstack('-completenames'); disp([err.message ' in the function ' ST.name]);                
        end
      
        return;
        
        
    end
        
  
   s = read_Annotation_having_tag(session,obj,'bhfileHeader');
        
   if ~isempty(s)  % found a BH annotation 
        ret.modulo = 'ModuloAlongC';
        ret.FLIM_type = 'TCSPC';

        pos = strfind(s, 'bins');
        nBins = str2double(s(pos+5:pos+7));

        pos = strfind(s, 'base');
        time_base = str2double(s(pos+5:pos+14)).*1000;        % get time base & convert to ps
    
        time_points = 0:nBins - 1;
        ret.delays = time_points.*(time_base/nBins);
   
        % Determine no of channels 
        ret.n_channels = ret.SizeC/nBins;
        
   end
   
   
        
   return;
       
   
        

end
