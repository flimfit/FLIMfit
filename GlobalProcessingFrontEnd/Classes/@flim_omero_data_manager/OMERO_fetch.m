function [delays, data_cube, name ] =  OMERO_fetch(obj, image, channel, ZCT, mdta)
    %> Load a single FLIM dataset
    
delays = [];
data_cube = [];

imageId = image.getId().getValue();
name = char(image.getName.getValue());

FLIM_type   = mdta.FLIM_type;
Delays      = mdta.delays;
modulo      = mdta.modulo;
n_channels  = mdta.n_channels;

if ~isempty(mdta.modulo)
    
     delays = cell2mat(Delays)';
     
else % still can process as it is an imported file.... 

    imageId = java.lang.Long(imageId); % oops
    %
    annotators = java.util.ArrayList;
    ann = [];
    metadataService = obj.session.getMetadataService();
    map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
    annotations = map.get(imageId); 
    
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);  
    
    if annotations.size() == 0
        % no annotation found - forced to assume a LaVision file imported
        % via insight!
        
        sizeZ = pixels.getSizeZ.getValue();
        if sizeZ > 2 & length(channel) == 1 & max(channel) == 1
              modulo = 'ModuloAlongZ';
              FLIM_type = 'TCSPC';
              n_channels = 1;
              
              physSizeZ = pixels.getPhysicalSizeZ().getValue().*1000;     % assume this is in ns so convert to ps
              delays = 0:sizeZ -1;
              delays = delays .* physSizeZ; 
              
        end
        
    else
    
        for j = 0:annotations.size()-1
            of = annotations.get(j);        
            if of.getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)
                ann = annotations.get(j);
            end
            
        end

      
        originalFile = ann.getFile();
        
        rawFileStore = obj.session.createRawFileStore();
        rawFileStore.setFileId(originalFile.getId().getValue());
        % open file and read it
        byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
        str = char(byteArr');
        % Important to close the service
        rawFileStore.close();
            
        if strfind(str,'bhfileHeader')
        
            modulo = 'ModuloAlongC';
            FLIM_type = 'TCSPC';

            pos = strfind(str, 'bins');
            nBins = str2num(str(pos+5:pos+7));

            pos = strfind(str, 'base');
            time_base = str2num(str(pos+5:pos+14)).*1000;        % get time base & convert to ps
    
            time_points = 0:nBins - 1;
            delays = time_points.*(time_base/nBins);
   
            % Determine which channels we need to load ? mmmm ?
             sizeC = pixels.getSizeC().getValue(); 
            n_channels = sizeC/nBins;
        end % end BH file 
    end     % end no annotations
        
end

if isempty(modulo)  % if file has been identified then load it
    
    errordlg('no suitable annotation found - can not continue');
    return;
else

    if ~isempty(mdta.n_channels) && mdta.SizeC~=1 && mdta.n_channels == mdta.SizeC && ~strcmp(mdta.modulo,'ModuloAlongC') % native multi-spectral FLIM     
        data_cube_ = get_FLIM_cube_Channels( obj.session, image, mdta.modulo, ZCT );
    else 
        data_cube_ = get_FLIM_cube( obj.session, image, n_channels, channel, modulo, ZCT );                
    end
            
    [nBins,sizeX,sizeY] = size(data_cube_);       
    data_cube = zeros(nBins,1,sizeX,sizeY,1);
    
    data_cube(1:end,1,:,:,1) = squeeze(data_cube_(1:end,:,:));   
    
    if FLIM_type ~= 'TCSPC'
        if min(data_cube(:)) > 32500
            data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
        end
    end
      
end
   