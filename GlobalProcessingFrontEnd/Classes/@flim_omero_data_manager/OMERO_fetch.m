function [ data_cube, name ] =  OMERO_fetch( obj, image, ZCT, mdta)
    
data_cube = [];

name = char(image.getName.getValue());

FLIM_type   = mdta.FLIM_type;
modulo      = mdta.modulo;
delays      = mdta.delays';

if isempty(modulo)    
    errordlg('no suitable annotation found - can not continue');
    return;
else

    data_cube = get_FLIM_cube( obj.session, image, length(delays), modulo, ZCT );                
         
    if strcmp('TCSPC',FLIM_type)
    
        %Bodge to suppress bright line artefact on RHS in BH .sdt files
        if strfind(name,'.sdt')
           data_cube(:,:,:,end,:) = 0;
        end
    else    % Not TCSPC
    
        if min(data_cube(:)) > 32500
            data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
        end
    end
      
end
   