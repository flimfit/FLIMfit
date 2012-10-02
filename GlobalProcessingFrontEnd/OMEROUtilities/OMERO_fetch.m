function [delays, data_cube, name ] =  OMERO_fetch(imageDescriptor, channel)
    %> Load a single FLIM dataset
    
delays = [];
data_cube = [];

session = imageDescriptor{1};     
imageID = imageDescriptor{2};
imageId = java.lang.Long(imageID);

proxy = session.getContainerService();

 % check original image ID is valid
ids = java.util.ArrayList();
ids.add(imageId); %add the id of the image.
list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());

if (list.size == 0)
    exception = MException('OMERO:ImageID', 'Image Id not valid');
    throw(exception);
    return;
end

image = list.get(0);
name = char(image.getName().getValue());

pixelsList = image.copyPixels();    
pixels = pixelsList.get(0);

sizeZ = pixels.getSizeZ().getValue(); 
sizeX = pixels.getSizeX().getValue();
sizeY = pixels.getSizeY().getValue();

pixelsId = pixels.getId().getValue();

% trying to get the original metadata in order to work out the time base & no of timePoints
annotators = java.util.ArrayList;
ann = [];
metadataService = session.getMetadataService();

map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());

annotations = map.get(imageId);
for j = 0:annotations.size()-1
    of = annotations.get(j);
    if of.getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)
        ann = annotations.get(j);
    end
end

if isempty(ann)  % no ORIGINAL_METADATA
    
    % forced to assume it's a lavision ome.tif
    
    if sizeZ < 4
        errordlg(' Invalid timePoints!');
        return;
    else
        nBins = sizeZ;
    end
        
    if max(channel) > 1  || length(channel) ~= 1
        errordlg('invalid channel!');
        return;
    end
    
    % attempt to get a matrix out
    data_cube = zeros(nBins,1,sizeX,sizeY,length(channel));
    
    store = session.createRawPixelsStore(); 
    store.setPixelsId(pixelsId, false);

     c = 0;
     t = 0;

     delays = (0:(nBins-1))/nBins*12.5e3;
     
     for bin = 1:nBins
        plane = store.getPlane(bin - 1, c, t);
        data_cube(bin,1,:,:,1) = toMatrix(plane, pixels);
     end
     
     store.close();
       
    
else        % found original metadata
    
    originalFile = ann.getFile();
        
    rawFileStore = session.createRawFileStore();
    rawFileStore.setFileId(originalFile.getId().getValue());

    %  open file and read it
    byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
    
    str = char(byteArr');
    
    if strfind(str,'bhfileHeader')      
       
         pos = strfind(str, 'bins');    % definitely a BH .sdt file
         if ~isempty(pos)        
            pos = pos(1);
            nBins = str2num(str(pos+5:pos+7));

            pos = strfind(str, 'base');
            pos = pos(1);
            time_base = str2num(str(pos+5:pos+14)).*1000;        % get time base & convert to ps
            
            sizeC = pixels.getSizeC().getValue(); 

            if nBins > 0
                n_channels = sizeC/nBins;   % for a .sdt file timeBins are stored in channels
            else
                n_channels = sizeC;
            end
         end
       
        
         if max(channel) > n_channels
            
            errordlg('Invalid channel');
            return;
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
                data_cube(bin,1,:,:,cc) = toMatrix(plane, pixels);
            end
        end
            
        %clear ridiculously bright pixels at bottom (RH side?? ) of image
        data_cube(:,:,end-1:end,:) = 0;
        
        time_points = 0:nBins- 1;
        delays = time_points.*(time_base/nBins);
        
        store.close();
        
    
    else
        % there is an ORIGINAL_METADATA annotation but it's not BH 
        % INSERT YURIY's handling code here!
        errordlg(' Unrecognised annotation!');
    end
    
    % Important to close the service
    rawFileStore.close();   
          
    end
    
   
   
end

 

   
