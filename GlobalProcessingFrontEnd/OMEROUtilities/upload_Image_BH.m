function upload_Image_BH(session, dataset, full_filename, pixeltype)         
    %
    bandhdata = loadBandHfile_CF(full_filename); % full filename
    %
    [ n_channels nBins w h ] = size(bandhdata);                            
    % get Delays
    [ImData Delays] = loadBHfileusingmeasDescBlock(full_filename, 1);
    Delays = repmat(Delays,1,n_channels);
    clear('ImData');                            
    %
    channels_names = cell(1,numel(Delays));
    for k = 1: numel(Delays)
        channels_names{k} = num2str(Delays(k));
    end;            
    %
    Z = zeros(n_channels*nBins, h, w);
    %
    for c = 1:n_channels,
        for b = 1:nBins,
            u = double(squeeze(bandhdata(c,b,:,:)))';                                    
            index = (c - 1)*nBins + b;
            Z(index,:,:) = u;
        end
    end;                                                    
    %
    img_description = ' ';
        str = split(filesep,full_filename);
            filename = str(length(str));
    imgId = mat2omeroImage_Channels(session, Z, pixeltype, filename,  img_description, channels_names);
        link = omero.model.DatasetImageLinkI;
        link.setChild(omero.model.ImageI(imgId, false));
        link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
        session.getUpdateService().saveAndReturnObject(link);     
       
% %     gateway = session.createGateway();
% %         image = gateway.getImage(imgId);                 
% %         %annotation - fixed
% %         add_Annotation_XML(session, image, ... 
% %                         'IC_PHOT_MULTICHANNEL_IMAGE_METADATA.xml', ... 
% %                         'IC_PHOT_MULTICHANNEL_image_annotation', ... 
% %                         '_',...
% %                         'number_of_channels', cellstr(num2str(n_channels)), 'delays', channels_names(1:nBins));
% %     %
% %     gateway.close();
% %     %

    proxy = session.getContainerService();
    ids = java.util.ArrayList();
    ids.add(java.lang.Long(imgId)); %add the id of the image.
    list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
    if (list.size == 0)
        exception = MException('OMERO:ImageID', 'Image Id not valid');
        throw(exception);
    end
    image = list.get(0);
        % annotation - fixed
        add_Annotation_XML(session, image, ... 
                        'IC_PHOT_MULTICHANNEL_IMAGE_METADATA.xml', ... 
                        'IC_PHOT_MULTICHANNEL_image_annotation', ... 
                        '_',...
                        'number_of_channels', cellstr(num2str(n_channels)), 'delays', channels_names(1:nBins));

end
