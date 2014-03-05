
function[dims,t_int ] = get_image_dimensions(obj, image)

% Finds the dimensions of an image file or set of files including 
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
    
    s = [];
    
    
    objId = image.getId();
    file = char(image.getName.getValue());      % filename
    
    pixelsList = image.copyPixels();
    pixels = pixelsList.get(0);
    
    seriesCount = r.getSeriesCount;
    if seriesCount > 1
        block = [];
        while isempty(block) ||  block > seriesCount ||  block < 1
            prompt = {['This file holds ' num2str(seriesCount) ' images. Please select one']};
            dlgTitle = 'Multiple images in File! ';
            defaultvalues = {'1'};
            numLines = 1;
            inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
            block = str2double(inputdata);
            
        end
        
        obj.block = block;
        
    else
        obj.block = 1;
    end
    
    r.setSeries(obj.block - 1);
    
    omeMeta = r.getMetadataStore();
    
    
    obj.bfOmeMeta = omeMeta;  % set for use in loading data
    obj.bfReader = r;
    
    
    
    sizeZCT(1) = pixels.getSizeZ().getValue();
    sizeZCT(2) = pixels.getSizeC().getValue();
    sizeZCT(3) = pixels.getSizeT().getValue();
    % NB x and y are swapped here! Because the images are transposed
    % during loading from OMERO. 
    sizeXY(1) = pixels.getSizeY().getValue();
    sizeXY(2) = pixels.getSizeX().getValue();
    
    
    
    % check for presence of an Xml modulo Annotation  containing 'Lifetime'
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
          
   
    % if no modulo annotation check for Imspector produced ome-tiffs &
    % legacy images
    if isempty(s)
        
        % support for Imspector produced ome-tiffs
        if findstr(file,'ome.tif')
            physZ = pixels.getPhysicalSizeZ(0).getValue();
            if 1 == sizeZCT(2) && 1 == sizeZCT(3) && sizeZCT(1) > 1
                physSizeZ = physZ.*1000;     % assume this is in ns so convert to ps
                dims.delays = (0:sizeZCT(1)-1)*physSizeZ;
                dims.modulo = 'ModuloAlongZ';
                dims.FLIM_type = 'TCSPC';
                sizeZCT(1) = sizeZCT(1)./length(dims.delays); 
            end
        end
        
        % support for legacy .sdt files lacking a modulo annotation
        if findstr(file,'.sdt')
            s = read_Annotation_having_tag(session,image,'ome.model.annotations.FileAnnotation','bhfileHeader');
            if ~isempty(s)      % found a BH file header FileAnnotation
                dims.modulo = 'ModuloAlongC';
                dims.FLIM_type = 'TCSPC';
                pos = strfind(s, 'bins');
                nBins = str2num(s(pos+5:pos+7));
                pos = strfind(s, 'base');
                time_base = str2num(s(pos+5:pos+14)).*1000;       % get time base & convert to ps   
                time_points = 0:nBins - 1;
                dims.delays = time_points.*(time_base/nBins);   
                sizeZCT(2) = sizeZCT(2)./length(dims.delays);
            end
        end
        
        
    else
        rdims = obj.parseModuloAnnotation(s, sizeZCT, []);
        if ~isempty(rdims)
            dims = rdims;
        end
        
        
        
        % get channel_names
        for c = 1:sizeZCT(2)
            chan_info{c} = omeMeta.getChannelName( 0 ,  c -1 );
            dims.chan_info = chan_info;
        end
    end
    
    
    dims.sizeXY = sizeXY;
    
    
       
    
    if length(t_int) ~= length(dims.delays)
        t_int = ones(size(dims.delays));
    end
    
end
    