function [delays, data_cube, name ] =  OMERO_fetch(obj, image, channel, ZCT, mdta)
    %> Load a single FLIM dataset
    
delays = [];
data_cube = [];

name = char(image.getName.getValue());

FLIM_type   = mdta.FLIM_type;
delays      = mdta.delays;
modulo      = mdta.modulo;
n_channels  = mdta.n_channels;


if isempty(modulo)  % if file has been identified then load it
    
    errordlg('no suitable annotation found - can not continue');
    return;
else

    if ~isempty(mdta.n_channels) && mdta.SizeC~=1 && mdta.n_channels == mdta.SizeC && ~strcmp(mdta.modulo,'ModuloAlongC') % native multi-spectral FLIM     
        data_cube_ = get_FLIM_cube_Channels( obj.session, image, mdta.modulo, ZCT );
    else 
        data_cube_ = get_FLIM_cube( obj.session, image, n_channels, channel, modulo, ZCT );                
    end
            
    [nBins,sizeX,sizeY] = size(data_cube_);       
    data_cube = zeros(nBins,1,sizeX,sizeY,1);
    
    data_cube(1:end,1,:,:,1) = squeeze(data_cube_(1:end,:,:));   
    
    if strcmp(FLIM_type,'TCSPC');
        if min(data_cube(:)) > 32500
            data_cube = data_cube - 32768;    % clear the sign bit which is set by labview
        end
    end
      
end
   