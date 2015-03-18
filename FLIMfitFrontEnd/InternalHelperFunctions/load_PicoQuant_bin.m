function [U, Delays, PixResol ] = load_PicoQuant_bin(filename,precision)

    fid = fopen(filename,'r');

    PixX = fread(fid,1,'uint32');
    PixY = fread(fid,1, 'uint32');
    PixResol = fread(fid,1, 'single'); % microns?
    TCSPCChannels = fread(fid,1, 'uint32');
    TimeResol = fread(fid,1, 'single');

    U = zeros(TCSPCChannels,PixY,PixX);

        switch precision
            case {'int8', 'uint8'}
                U = uint8(U);
            case {'uint16','int16'}
                U = uint16(U);
            case {'uint32','int32'}
                U = uint32(U);
            case {'single'}
                U = float(U);
        end                                

    for y = 1:PixX
        for x = 1:PixY
            U(:,y,x) = fread(fid,TCSPCChannels,precision);
        end
    end;

    fclose(fid);
    
    Delays = ((1:TCSPCChannels)-1)*TimeResol;

    if TimeResol < 1 
        Delays = Delays*1e3; 
    end; %to picoseconds

end