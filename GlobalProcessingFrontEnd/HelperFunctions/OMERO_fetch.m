function [delays, data_cube, name ] =  OMERO_fetch(imageDescriptor, channel, ZCT)
    %> Load a single FLIM dataset
    
delays = [];
data_cube = [];

session = imageDescriptor{1};     
imageID = imageDescriptor{2};
imageId = java.lang.Long(imageID);

proxy = session.getContainerService();
    ids = java.util.ArrayList();
        ids.add(imageId); %add the id of the image.
            list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
    if (list.size == 0)
        exception = MException('OMERO:ImageID', 'Image Id not valid');
        throw(exception);
    end
image = list.get(0);

name = char(image.getName().getValue());

modulo = 'ModuloAlongC'; % default 

if ~image_is_BH(session,image) % follow PHOT route to get no channels etc.
    %
    [ FLIM_type Delays modulo n_channels ] = get_FLIM_params_from_metadata(session,image.getId(),'metadata.xml');
    delays = cell2mat(Delays)';
    %    
else % still can process as it is an imported sdt.... 

    annotators = java.util.ArrayList;
    ann = [];
    metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
            annotations = map.get(imageId);   
    %
    for j = 0:annotations.size()-1
        of = annotations.get(j);        
        if of.getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)
            ann = annotations.get(j);
        end
    end

    if isempty(ann)
        errordlg('no suitable annotation found - can not continue')
    end;
    
    originalFile = ann.getFile();
        
    rawFileStore = session.createRawFileStore();
    rawFileStore.setFileId(originalFile.getId().getValue());

    %  open file and read it
    byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
    str = char(byteArr');

    pos = findstr(str, 'bins');
    nBins = str2num(str(pos+5:pos+7));

    pos = findstr(str, 'base');
    time_base = str2num(str(pos+5:pos+14)).*1000;        % get time base & convert to ps

    % Important to close the service
    rawFileStore.close();
    
    time_points = 0:nBins - 1;
    delays = time_points.*(time_base/nBins);
   
    % Determine which channels we need to load ? mmmm ?

    pixelsList = image.copyPixels();    
        pixels = pixelsList.get(0);    
            sizeC = pixels.getSizeC().getValue(); 
    n_channels = sizeC/nBins;
    
end

    data_cube_ = get_Channels( session, imageID, n_channels, channel, modulo, ZCT );            
    %
    [nBins,sizeX,sizeY] = size(data_cube_);        
    data_cube = zeros(nBins,1,sizeX,sizeY,1);
    %
    for bin = 1:nBins
        data_cube(bin,1,:,:,1) = squeeze(data_cube_(bin,:,:));
    end                  
    %
    if min(data_cube(:)) > 32500
        data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
    end
            
end