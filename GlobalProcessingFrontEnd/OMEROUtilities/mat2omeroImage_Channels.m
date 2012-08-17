function imageId = mat2omeroImage_Channels(factory, data, pixeltype, imageName, description, channels_names)

            if isempty(factory) ||  isempty(data) || isempty(imageName)
                errordlg('upload_Image: bad input');
                return;
            end;                   
            %
            [sizeC,sizeX,sizeY] = size(data);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Channels only
            sizeT = 1;
            sizeZ = 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        

queryService = factory.getQueryService();
pixelsService = factory.getPixelsService();
rawPixelsStore = factory.createRawPixelsStore(); 
containerService = factory.getContainerService();

% Lookup the appropriate PixelsType, depending on the type of data you have:
p = omero.sys.ParametersI();
p.add('type',rstring(pixeltype));       

q=['from PixelsType as p where p.value= :type'];
pixelsType = queryService.findByQuery(q,p);


% Use the PixelsService to create a new image of the correct dimensions:
iId = pixelsService.createImage(sizeX, sizeY, sizeZ, sizeT, toJavaList([uint32(0:(sizeC - 1))]), pixelsType, char(imageName), char(description));
imageId = iId.getValue();

% Then you have to get the PixelsId from that image, to initialise the rawPixelsStore. I use the containerService to give me the Image with pixels loaded:
image = containerService.getImages('Image',  toJavaList(uint64(imageId)),[]).get(0);
pixels = image.getPrimaryPixels();
pixelsId = pixels.getId().getValue();
rawPixelsStore.setPixelsId(pixelsId, true);

for c = 1:sizeC % k is channel number    
    plane = squeeze(data(c,:,:));    
    bytear=omerojava.util.GatewayUtils.convertClientToServer(pixels, plane) ;
    rawPixelsStore.setPlane(bytear, int32(0),int32(c - 1),int32(0));        
    %
    nans = sum(sum(isnan(plane)));
    infs = sum(sum(isinf(plane)));    
    if 0 == (nans + infs)
        minVal = min(min(plane));
        maxVal = max(max(plane));   
        pixelsService.setChannelGlobalMinMax(pixelsId, c - 1, minVal, maxVal);                
    end;
end 
%
%%%%%%%%%%%%% set channels names if specified
if nargin == 6 && ~isempty(channels_names) && sizeC == numel(channels_names)
    %
    pixelsDesc = pixelsService.retrievePixDescription(pixels.getId().getValue());
    channels = pixelsDesc.copyChannels();
    %         
    for c = 1:sizeC
        ch = channels.get(c - 1);
        ch.getLogicalChannel().setName(omero.rtypes.rstring(char(channels_names{c})));
        factory.getUpdateService().saveAndReturnObject(ch.getLogicalChannel());
    end                                                        
end;
%%%%%%%%%%%%% channels names
%
rawPixelsStore.save();
rawPixelsStore.close();
%
RENDER = true;


re = factory.createRenderingEngine();
%
re.lookupPixels(pixelsId)
    if ~re.lookupRenderingDef(pixelsId)
        re.resetDefaults();  
    end;
    if ~re.lookupRenderingDef(pixelsId)
        errordlg('mat2omeroImage_Channels: can not render properly');
        RENDER = false;
    end
%
if RENDER
    % start the rendering engine
    re.load();
    % optional setting of rendering 'window' (levels)
    %renderingEngine.setChannelWindow(cIndex, float(minValue), float(maxValue))
    %
    alpha = 255;
    switch sizeC % likely RGB
        case 3
            re.setRGBA(0, 255, 0, 0, alpha);
            re.setRGBA(1, 0, 255, 0, alpha);
            re.setRGBA(2, 0, 0, 255, alpha);
        otherwise
            for c = 1:sizeC,
                re.setRGBA(c - 1, 255, 255, 255, alpha);
            end
    end
    %
    re.saveCurrentSettings();
end;

re.close();