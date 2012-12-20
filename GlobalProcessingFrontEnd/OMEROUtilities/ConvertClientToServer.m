function [ byteStream ] = ConvertClientToServer(  pixels, data )
%fromMatrix converts a 2d matlab array to a bytestream 
%   ready to use in OMERO rawDataStore.setPlane
% possible replacement for GatewayUtils convertClienttoServer

    [ sizeX sizeY ] = size(data);

    sizexp = pixels.getSizeX().getValue();
    sizeyp = pixels.getSizeY().getValue();

    if sizeX ~= sizexp || sizeY ~= sizeyp
        return;
    end

    pixType = char(pixels.getPixelsType().getValue().getValue());
    
    if ~strcmp(class(data), pixType)
        %NB casting like this is dodgy!! Better to throw an error
        data = cast(data,pixType);
    end

    ar = reshape(data, sizeX * sizeY, 1 );
    ar = swapbytes(ar);     % not quite sure why? Copied from toMatrix
    byteStream = typecast(ar, 'int8');
    

end

