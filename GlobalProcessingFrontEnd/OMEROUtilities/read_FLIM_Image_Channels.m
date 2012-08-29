function [ data_cube delays name ] = read_FLIM_Image_Channels( session, imgId, channel )
%
    data_cube = []; 
    delays = [];
    %
    gateway = session.createGateway();
        image = gateway.getImage(imgId);
    gateway.close();
        name = char(image.getName().getValue());
    %
    [ n_channels_str delays_str ] = read_Annotation_XML(session, image, ...                                    
                                        'IC_PHOT_MULTICHANNEL_IMAGE_METADATA.xml', ...
                                        'number_of_channels', ...
                                        'delays');
                                    
    if ~isempty(n_channels_str) || ~isempty(delays_str)
        n_channels = str2num(cell2mat(n_channels_str));
        delays = str2num(char(delays_str));
    else
        errordlg(['Image ' name ' annotation is missing or broken - can not continue']);
        return;
    end;
    %
    %
    data_cube = get_Channels( session, imgId, n_channels, channel );
end

