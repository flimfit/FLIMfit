function[dims,reader_settings,meta] = get_image_dimensions(obj, image)

% Finds the dimensions of an OMERO image or set of images including 
% the units along the time dimension (delays)


    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % if image is in fact a filename then call the superclass method
    % instead
    
    
    if strfind(class(image),'char')
        [dims,reader_settings,meta] = get_image_dimensions@flim_data_series(obj, image);
        return;
    else
        meta.rep_rate = nan;
    end
    
    reader_settings = struct();
    
    dims.t_int = [];
    dims.delays = [];
    dims.modulo = 'none';
    dims.FLIM_type = [];
    dims.sizeZCT = [];
    dims.data_type = 'single';
    
    
    dims.chan_info = [];
    
    
    % No requirement for looking at series_count as OMERO stores each block
    % as a separate image
    
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
    
    
    sizeZCT(1) = pixels.getSizeZ.getValue();
    sizeZCT(2) = pixels.getSizeC.getValue();
    sizeZCT(3) = pixels.getSizeT.getValue();
    % NB This is nasty! sizeX & Y are reversed here as we want to retain
    % compatibilty with earlier versions of FLIMfit
    % TBD rotate display rather than transposing all data on import from
    % OMERO !
    sizeXY(1) = pixels.getSizeY.getValue();
    sizeXY(2) = pixels.getSizeX.getValue();
    
    data_type = char(pixels.getPixelsType().getValue().getValue());
    if ~any(strcmp(data_type,{'uint32','uint16'}))
        data_type = 'single';
    end
    dims.data_type = data_type;
    
    
    session = obj.omero_logon_manager.session;
        
    % check for presence of an Xml modulo Annotation  containing 'Lifetime'
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
          
 
    % if no modulo annotation check for Imspector produced ome-tiffs.
    if isempty(s)
        if strfind(char(image.getName.getValue() ),'ome.tif')
            if sizeZCT(1) > 1 && sizeZCT(2) == 1 && sizeZCT(3) == 1
                physZ = pixels.getPhysicalSizeZ();
                if ~isempty(physZ)
                    physSizeZ = physZ.getValue() .* 1000;    % assume this is in ns so convert to ps
                    dims.delays = (0:sizeZCT(1)-1)*physSizeZ;
                    dims.modulo = 'ModuloAlongZ';
                    dims.FLIM_type = 'TCSPC';
                    sizeZCT(1) = sizeZCT(1)./length(dims.delays);
                end
            end
        end
    
    else
        dims = obj.parse_modulo_annotation(s, sizeZCT, dims);
      
        % get channel_names 
        pixelsService = session.getPixelsService();
        pixelsDesc = pixelsService.retrievePixDescription(pixels.getId().getValue());
        channels = pixelsDesc.copyChannels();
       
        dims.chan_info = [];
        for c = 1:sizeZCT(2)
             name = channels.get(c -1).getLogicalChannel().getName();
             if ~isempty(name)
                dims.chan_info{c} = char(name.getValue());
             else
                 wave = channels.get(c -1).getLogicalChannel().getEmissionWave();
                 if ~isempty(wave)
                    dims.chan_info{c} = char(wave.getValue());
                 else
                    dims.chan_info{c} = ['Channel ' num2str(c-1)];
                 end
             end
        end
             
    end
        
        
    dims.sizeXY = sizeXY;
    dims.sizeZCT = sizeZCT;
        
    if isempty(dims.delays)
        dims.error_message = 'Unable to load! Not time resolved data.';
    end
    
    if length(dims.t_int) ~= length(dims.delays)
        dims.t_int = ones(size(dims.delays));
    end
        
end
