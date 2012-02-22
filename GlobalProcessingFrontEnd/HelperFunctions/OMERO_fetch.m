function [delays, data_cube, name ] =  OMERO_fetch(imageDescriptor, channel)
    %> Load a single FLIM dataset
    
    delays = [];
    data_cube = [];
    
   
    polarisation_resolved = false;
    
    
    session = imageDescriptor{1};
    
    imageID = imageDescriptor{2}
    
    imageId = java.lang.Long(imageID);
   
   
   proxy = session.getContainerService();


    list = proxy.getImages(omero.model.Image.class, java.util.Arrays.asList(imageId), omero.sys.ParametersI());
    if (list.size == 0)
        exception = MException('OMERO:ImageID', 'Image Id not valid');
        throw(exception);
        return;
    end

    image = list.get(0);

    pixelsList = image.copyPixels();
    
    name = char(image.getName.getValue());  % char converts to matlab

    pixels = pixelsList.get(0);

    sizeX = pixels.getSizeX().getValue();
    sizeY = pixels.getSizeY().getValue(); 
    sizeT = pixels.getSizeT().getValue();
    sizeC = pixels.getSizeC().getValue(); 

    pixelsId = pixels.getId().getValue();

    
    % getting metadata to find sizet (no of time_bins) & time base
    %userId = session.getAdminService().getEventContext().userId;
    annotators = java.util.ArrayList;

    

    metadataService = session.getMetadataService();
    % retrieve the annotations linked to images, for datasets use: omero.model.Dataset.class
    %annotations = metadataService.loadSpecifiedAnnotations(omero.model.FileAnnotation.class, nsToInclude, nsToExclude, options);
    map = metadataService.loadAnnotations(omero.model.Image.class, java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
    annotations = map.get(imageId);

    for j = 0:annotations.size()-1
        of = annotations.get(j);
        %of.getNamespace().getValue().equals('your_name_space');
        if of.getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)
            ann = annotations.get(j);
        end
    end

    originalFile = ann.getFile();
    
    


    rawFileStore = session.createRawFileStore();
    rawFileStore.setFileId(originalFile.getId().getValue());

    %  open file and read it
    byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
    str = char(byteArr');

    pos = findstr(str, 'bins');
    nBins = str2num(str(pos+5:pos+7))

    pos = findstr(str, 'base');
    time_base = str2num(str(pos+5:pos+14)).*1000        % get time base & convert to ps

    % Important to close the service
    rawFileStore.close();

    %metadataService.close();
    
    time_points = 0:nBins- 1
    delays = time_points.*(time_base/nBins)
   
    % Determine which channels we need to load 
     
    
    n_channels_present = sizeC/nBins;
    
    if n_channels_present > 1
        
        
        if max(channel) > n_channels_present
            
            exception = MException('OMERO:InvalidChannel', 'Invalid channel');
            throw(exception);
        end
        
       
    else
        channel = 1;
    end
    
 
    
    
    
    
    % chnnels here are BH channels (load one dataset from the  channel
    % selected by the user 
    
    
    % attempt to get a matrix out
    data_cube = zeros(nBins,1,sizeX,sizeY,length(channel));
    store = session.createRawPixelsStore(); 
    store.setPixelsId(pixelsId, false);

    z = 0;
    t = 0;

    for cc = 1:length(channel)
    % c here is OMERO 'channels' ie time-bins ??? 
        chan  = channel(cc) -1;        % change to c++ style numbering
        c = chan * nBins;
       
        for bin = 1:nBins
            plane = store.getPlane(z, c, t);
            c = c +1;
            data_cube(bin,1,:,:,chan+1) = toMatrix(plane, pixels);
        end
    end
            
    

    %clear ridiculously bright pixels at bottom (RH side?? ) of image
    data_cube(:,:,end-1:end,:) = 0;

    
   

end