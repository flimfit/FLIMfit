function upload_Image_BH(session, dataset, full_filename,contents_type)
    %
    bandhdata = loadBandHfile_CF(full_filename); % full filename
    %
    [ n_channels nBins w h ] = size(bandhdata);                            
    % get Delays
    [ImData Delays] = loadBHfileusingmeasDescBlock(full_filename, 1);
    Delays = repmat(Delays,1,n_channels);
    %
% %     pixeltype = 'double';
% %     if     isa(ImData,'uint16'), pixeltype = 'uint16';
% %     elseif isa(ImData,'int16'), pixeltype = 'int16';
% %     elseif isa(ImData,'uint8'), pixeltype = 'uint8';
% %     elseif isa(ImData,'int8'), pixeltype = 'int8';
% %     elseif isa(ImData,'uint32'), pixeltype = 'uint32';
% %     elseif isa(ImData,'int32'), pixeltype = 'int32';
% %     elseif isa(ImData,'uint64'), pixeltype = 'uint64';
% %     elseif isa(ImData,'int64'), pixeltype = 'int64';
% %     end
    pixeltype = get_num_type(ImData); % NOT CHECKED!!!
    %
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
    %
    imgId = mat2omeroImage_Channels(session, Z, pixeltype, filename,  img_description, channels_names);
    %
    link = omero.model.DatasetImageLinkI;
        link.setChild(omero.model.ImageI(imgId, false));
            link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                session.getUpdateService().saveAndReturnObject(link);     
    % BLOCK ABOVE
%     proxy = session.getContainerService();
%     ids = java.util.ArrayList();
%     ids.add(java.lang.Long(imgId)); %add the id of the image.
%     list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
%     if (list.size == 0)
%         exception = MException('OMERO:ImageID', 'Image Id not valid');
%         throw(exception);
%     end
%     image = list.get(0);
    % BLOCK ABOVE
    image = get_Object_by_Id(session,imgId.getValue()); % this must do  block above
    %
    % OME ANNOTATION
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.BigEndian = 'true';
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.DimensionOrder = 'XYCTZ'; % does not matter
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.ID = '?????';
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.PixelType = pixeltype;
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeX = h; % :)
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeY = w;
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = 1;
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = n_channels*nBins;
    flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = 1;
    %
    flimXMLmetadata.Image.ContentsType = contents_type;
    flimXMLmetadata.Image.FLIMType = 'TCSPC';
    %
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.ATTRIBUTE.ID = 'Annotation:3'; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.ATTRIBUTE.Namespace = 'openmicroscopy.org/omero/dimension/modulo'; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ATTRIBUTE.namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09'; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Type = 'lifetime'; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.NumberOfFLIMChannels = n_channels; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit = 'ps'; 
    flimXMLmetadata.StructuredAnnotation.XMLAnnotation.Value.Modulo.ModuloAlongC.Label = channels_names(1:nBins); 
    %
    xmlFileName = [tempdir 'metadata.xml'];
    xml_write(xmlFileName,flimXMLmetadata);
    %
    namespace = 'IC_PHOTONICS';
    description = ' ';
    %
    sha1 = char('pending');
    file_mime_type = char('application/octet-stream');
    %
    add_Annotation(session, ...
                    image, ...
                    sha1, ...
                    file_mime_type, ...
                    xmlFileName, ...
                    description, ...
                    namespace);    
    %
    delete(xmlFileName);
%
end
