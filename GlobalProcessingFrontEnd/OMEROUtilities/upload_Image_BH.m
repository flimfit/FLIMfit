function upload_Image_BH(session, dataset, full_filename, contents_type, modulo)

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
                
    bandhdata = loadBandHfile_CF(full_filename); % full filename
    
    if 2==numel(size(bandhdata)), errordlg('not an sdt FLIM image - not loaded'), return, end;
    %
    img_description = ' ';
    %str = split(filesep,full_filename);
    strings1 = strrep(full_filename,filesep,'/');
    str = split('/',strings1);            
    filename = str(length(str));    
    %
    single_channel = (3==numel(size(bandhdata)));    
    %
    if ~single_channel    
        [ n_channels nBins w h ] = size(bandhdata);                            
    else
        n_channels = 1;
        [ nBins w h ] = size(bandhdata);                                    
    end;
    % to get Delays
        [ImData Delays] = loadBHfileusingmeasDescBlock(full_filename, 1);
    %
    pixeltype = get_num_type(bandhdata); % NOT CHECKED!!!
    %
    clear('ImData');                            
    %
    sizeX = h;
    sizeY = w;
    sizeC = n_channels; 
        
        if strcmp(modulo,'ModuloAlongT') || strcmp(modulo,'ModuloAlongC') % criminal...
            sizeZ = 1;
            sizeT = nBins;            
        elseif strcmp(modulo,'ModuloAlongZ')
            sizeZ = nBins;
            sizeT = 1;            
        end
                        
        data = zeros(sizeX,sizeY,sizeZ,sizeC,sizeT);

            for c = 1:sizeC 
                for z = 1:sizeZ
                    for t = 1:sizeT
                        switch modulo
                            case 'ModuloAlongT'
                                k = t;
                            case 'ModuloAlongZ'
                                k = z;
                        end
                        %
                        if ~single_channel
                            u = double(squeeze(bandhdata(c,k,:,:)))';
                        else
                            u = double(squeeze(bandhdata(k,:,:)))';
                        end                                                                                                
                        data(:,:,z,c,t) = u;                        
                    end
                end
            end              
        %
        imgId = mat2omeroImage_native(session, data, pixeltype, filename,  img_description, []);
        %
        link = omero.model.DatasetImageLinkI;
            link.setChild(omero.model.ImageI(imgId, false));
                link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                    session.getUpdateService().saveAndReturnObject(link);     
        %
        myimages = getImages(session,imgId); image = myimages(1);        
        %        
        xmlnode = create_ModuloAlongDOM(Delays, [], modulo, 'TCSPC');
        add_XmlAnnotation(session,image,xmlnode);
        %
        add_Original_Metadata_Annotation(session,image,full_filename);
        %
end
