function imageId = mat2omeroImage_native(factory, data, pixeltype, imageName, description, channels_names)

imageId = [];

            if isempty(factory) ||  isempty(data) || isempty(imageName)
                errordlg('upload_Image: bad input');
                return;
            end;                   
            %
            [sizeX,sizeY,sizeZ,sizeC,sizeT] = size(data);
            %
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

minVal = min(data(:));
maxVal = max(data(:));

            for c = 1:sizeC 
                for z = 1:sizeZ
                    for t = 1:sizeT
                        plane = squeeze(data(:,:,z,c,t));    
                        bytear=omerojava.util.GatewayUtils.convertClientToServer(pixels, plane) ;
                        rawPixelsStore.setPlane(bytear, int32(z-1), int32(c-1), int32(t-1));                
                    end
                end
            pixelsService.setChannelGlobalMinMax(pixelsId, c-1, minVal, maxVal);                                
            end                         

if ~isempty(channels_names) && sizeC == numel(channels_names)
    %
    pixelsDesc = pixelsService.retrievePixDescription(pixels.getId().getValue());
    channels = pixelsDesc.copyChannels();
    %         
    for c = 1:sizeC
        ch = channels.get(c-1);
        ch.getLogicalChannel().setName(omero.rtypes.rstring(char(channels_names{c})));
        factory.getUpdateService().saveAndReturnObject(ch.getLogicalChannel());
    end                                                        
end;    
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
        errordlg('mat2omeroImage_native: can not render properly');
        RENDER = false;
    end
%
if RENDER
    try
        % start the rendering engine
        re.load();
        % optional setting of rendering 'window' (levels)
        %renderingEngine.setChannelWindow(cIndex, float(minValue), float(maxValue))
        %
        alpha = 255;
        for c = 1:sizeC,
            re.setRGBA(c - 1, 255, 255, 255, alpha);
        end
        %
        re.saveCurrentSettings();
    catch err
        [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
    end
end;

re.close();

end