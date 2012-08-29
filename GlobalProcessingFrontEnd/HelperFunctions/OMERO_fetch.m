function [delays, data_cube, name ] =  OMERO_fetch(imageDescriptor, channel)
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

if ~image_is_BH(session,image) % follow PHOT route to get no channels etc.
    
    [ n_channels_str delays_str ] = read_Annotation_XML(session, image, ...                                    
                                        'IC_PHOT_MULTICHANNEL_IMAGE_METADATA.xml', ...
                                        'number_of_channels', ...
                                        'delays');
                                    
    if ~isempty(n_channels_str) || ~isempty(delays_str)
        n_channels = str2num(cell2mat(n_channels_str));
        delays = str2num(char(delays_str))';
    else
        errordlg(['Image ' name ' annotation is missing or broken - can not continue']);
        return;
    end;
    %    
else % still can process if that is an imported sdt or other multi-channel image 

    annotators = java.util.ArrayList;
    ann = [];
    metadataService = session.getMetadataService();
        map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
            annotations = map.get(imageId);   
    for j = 0:annotations.size()-1
        of = annotations.get(j);
        %of.getNamespace().getValue().equals('your_name_space');
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

    data_cube_ = get_Channels( session, imageID, n_channels, channel );            
    %
    [nBins,sizeX,sizeY] = size(data_cube_);        
    data_cube = zeros(nBins,1,sizeX,sizeY,1);
    %
    for bin = 1:nBins
        data_cube(bin,1,:,:,1) = squeeze(data_cube_(bin,:,:));
    end                  
    % also see in "load_flim_file.m"...
    if min(data_cube(:)) > 32500
        data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
    end
    
% %     [nBins,sizeX,sizeY] = size(data_cube_);        
% %     data_cube = zeros(nBins,1,sizeY,sizeX,1);
% %     %
% %     for bin = 1:nBins
% %         data_cube(bin,1,:,:,1) = squeeze(data_cube_(bin,:,:))';
% %     end                        



% % 
% % 
% %     delays = [];
% %     data_cube = [];
% %        
% %     polarisation_resolved = false;
% %         
% %     session = imageDescriptor{1};
% %     
% %     imageID = imageDescriptor{2};
% %     
% %     imageId = java.lang.Long(imageID);
% %       
% %    proxy = session.getContainerService();
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS WASN'T WORKING - YA May 30    
% % % %     list = proxy.getImages(omero.model.Image.class, java.util.Arrays.asList(imageId), omero.sys.ParametersI());
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS WASN'T WORKING - YA May 30    
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% YA May 30
% % ids = java.util.ArrayList();
% % ids.add(imageId); %add the id of the image.
% % list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% YA May 30    
% % 
% %     if (list.size == 0)
% %         exception = MException('OMERO:ImageID', 'Image Id not valid');
% %         throw(exception);
% %         return;
% %     end
% % 
% %     image = list.get(0);
% % 
% %     pixelsList = image.copyPixels();
% %     
% %     name = char(image.getName.getValue());  % char converts to matlab
% % 
% %     pixels = pixelsList.get(0);
% % 
% %     sizeX = pixels.getSizeX().getValue();
% %     sizeY = pixels.getSizeY().getValue(); 
% %     sizeT = pixels.getSizeT().getValue();
% %     sizeC = pixels.getSizeC().getValue(); 
% % 
% %     pixelsId = pixels.getId().getValue();
% %     
% %     % getting metadata to find sizet (no of time_bins) & time base
% %     %userId = session.getAdminService().getEventContext().userId;
% %     annotators = java.util.ArrayList;
% %     
% %     metadataService = session.getMetadataService();
% %     % retrieve the annotations linked to images, for datasets use: omero.model.Dataset.class
% %     %annotations = metadataService.loadSpecifiedAnnotations(omero.model.FileAnnotation.class, nsToInclude, nsToExclude, options);
% %     
% %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS WASN'T WORKING - YA May 30    
% %     % map = metadataService.loadAnnotations(omero.model.Image.class, java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
% %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS WASN'T WORKING - YA May 30    
% %     
% %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% YA May 30    
% %     map = metadataService.loadAnnotations('omero.model.Image', java.util.Arrays.asList(imageId), java.util.Arrays.asList('ome.model.annotations.FileAnnotation'), annotators, omero.sys.ParametersI());
% %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% YA May 30
% %     annotations = map.get(imageId);
% %     
% %     for j = 0:annotations.size()-1
% %         of = annotations.get(j);
% %         %of.getNamespace().getValue().equals('your_name_space');
% %         if of.getFile().getName().getValue().contains(pojos.FileAnnotationData.ORIGINAL_METADATA_NAME)
% %             ann = annotations.get(j);
% %         end
% %     end
% % 
% %     originalFile = ann.getFile();
% %         
% %     rawFileStore = session.createRawFileStore();
% %     rawFileStore.setFileId(originalFile.getId().getValue());
% % 
% %     %  open file and read it
% %     byteArr  = rawFileStore.read( 0,originalFile.getSize().getValue());
% %     str = char(byteArr');
% % 
% %     pos = findstr(str, 'bins');
% %     nBins = str2num(str(pos+5:pos+7));
% % 
% %     pos = findstr(str, 'base');
% %     time_base = str2num(str(pos+5:pos+14)).*1000;        % get time base & convert to ps
% % 
% %     % Important to close the service
% %     rawFileStore.close();
% % 
% %     %metadataService.close();
% %     
% %     time_points = 0:nBins- 1;
% %     delays = time_points.*(time_base/nBins);
% %    
% %     % Determine which channels we need to load 
% %          
% %     n_channels_present = sizeC/nBins;
% %     
% %     if n_channels_present > 1
% %                 
% %         if max(channel) > n_channels_present
% %             
% %             exception = MException('OMERO:InvalidChannel', 'Invalid channel');
% %             throw(exception);
% %         end
% %                
% %     else
% %         channel = 1;
% %     end
% %                    
% %     % channels here are BH channels (load one dataset from the  channel
% %     % selected by the user 
% %         
% %     % attempt to get a matrix out
% %     data_cube = zeros(nBins,1,sizeX,sizeY,length(channel));
% %     store = session.createRawPixelsStore(); 
% %     store.setPixelsId(pixelsId, false);
% % 
% %     z = 0;
% %     t = 0;
% % 
% %     for cc = 1:length(channel)
% %     % c here is OMERO 'channels' ie time-bins ??? 
% %         chan  = channel(cc) -1;        % change to c++ style numbering
% %         c = chan * nBins;
% %        
% %         for bin = 1:nBins
% %             plane = store.getPlane(z, c, t);
% %             c = c + 1;
% %             data_cube(bin,1,:,:,chan+1) = toMatrix(plane, pixels);
% %         end
% %     end
% %                 
% %     %clear ridiculously bright pixels at bottom (RH side?? ) of image
% %     data_cube(:,:,end-1:end,:) = 0;
% %     
% %     store.close();       
end