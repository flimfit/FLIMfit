
function[dims,t_int ] = get_image_dimensions(obj, image)

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

    
    t_int = [];
    dims.delays = [];
    dims.modulo = [];
    dims.FLIM_type = [];
    dims.sizeZCT = [];
    
    
    dims.chan_info = [];
    
    
    % No requirement for looking at series_count as OMERO stores each block
    % as a separate image
    
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
    
    
    sizeZCT(1) = pixels.getSizeZ.getValue();
    sizeZCT(2) = pixels.getSizeC.getValue();
    sizeZCT(3) = pixels.getSizeT.getValue();
    sizeXY(1) = pixels.getSizeX.getValue();
    sizeXY(2) = pixels.getSizeY.getValue();
    
    session = obj.omero_data_manager.session;
        
    % check for presence of an Xml modulo Annotation  containing 'Lifetime'
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
          
 
    % if no modulo annotation check for Imspector produced ome-tiffs.
    % NB no support for FLIM .ics files in OMERO
    if isempty(s)
        if findstr(char(image.getName.getValue() ),'ome.tif')
            physZ = pixels.getPhysicalSizeZ(0).getValue();
            if 1 == sizeZCT(2) && 1 == sizeZCT(3) && sizeZCT(1) > 1
                physSizeZ = physZ.*1000;     % assume this is in ns so convert to ps
                dims.delays = (0:sizeZCT(1)-1)*physSizeZ;
                dims.modulo = 'ModuloAlongZ';
                dims.FLIM_type = 'TCSPC';
                sizeZCT(1) = sizeZCT(1)./length(dims.delays);
            end
        end
    
    else
        rdims = obj.parse_modulo_annotation(s, sizeZCT );
        if ~isempty(rdims)
            dims = rdims;
        end
      
        % get channel_names  TBD for OMERO
        dims.chan_info = [];
        % for c = 1:sizeZCT(2)
        %    chan_info{c} = omeMeta.getChannelName( 0 ,  c -1 );
        %    dims.chan_info = chan_info;
        % end
    end
        
        
    dims.sizeXY = sizeXY;
        
 
    if length(t_int) ~= length(dims.delays)
        t_int = ones(size(dims.delays));
    end
        
end
