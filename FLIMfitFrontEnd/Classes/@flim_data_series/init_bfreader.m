function [ext,r] = init_bfreader(obj,file)

    % init_bfreader attempts to set up a bio-Formats reader for file
    % if successful it returns the extension ext as 'bio" except in the
    % case of tiff files §§
    % otherwise ext is ret urned depending on the filename extension
    
    % Copyright (C) 2016 Imperial College London.
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

   
    try
        % Get the channel filler
        r = loci.formats.ChannelFiller();
        r = loci.formats.ChannelSeparator(r);
        
        OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
        r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());
        
        r.setId(file);
        
        % filter out .tiffs for separate handling
        format = char(r.getFormat());
        %  trapdoor for formats that need to be handled outside Bio-Formats
        switch(format)
        case 'Tagged Image File Format'
            ext = '.tif'; 
        otherwise
            ext = '.bio';
        end
        
    catch exception
        % bioformats does not recognise the file
        % so work on the filename
        [path,name,ext] = fileparts_inc_OME(file);  
    end
