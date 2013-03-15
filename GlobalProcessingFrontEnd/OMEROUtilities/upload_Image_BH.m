function upload_Image_BH(session, dataset, full_filename, contents_type, modulo, mode)

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
        % get Delays
        [ImData Delays] = loadBHfileusingmeasDescBlock(full_filename, 1);
        Delays = repmat(Delays,1,n_channels);
        %
% %     pixeltype = 'double';
% %     if     isa(ImData,'uint16'), pixeltype = 'uint16';
% %     elseif isa(ImData,'int16'), pixeltype = 'int16';
% %     elseif isa(ImData,'uint8'), pixeltype = 'uint8';
% %     elseif isa(ImData,'int8'), pixeltype = 'int8';
% %     elseif isa(ImData,'uint32'), pixeltype = 'uint32';
% %     elseif isa(ImData,'int32'), pixeltype = 'int32';
% %     elseif isa(ImData,'uint64'), pixeltype = 'uint64';
% %     elseif isa(ImData,'int64'), pixeltype = 'int64';
% %     end
    pixeltype = get_num_type(ImData); % NOT CHECKED!!!
    %
    clear('ImData');                            
    %
    channels_names = cell(1,numel(Delays));
    for k = 1: numel(Delays)
        channels_names{k} = num2str(Delays(k));
    end;            
    %
    % OME ANNOTATION        
    ome_params.BigEndian = 'true';
    ome_params.DimensionOrder = 'XYCTZ';
    ome_params.pixeltype = pixeltype;
    ome_params.SizeX = h;
    ome_params.SizeY = w;
    ome_params.modulo = modulo;
    ome_params.delays = channels_names(1:nBins);
    ome_params.FLIMType = 'TCSPC';
    ome_params.ContentsType = contents_type;
    %
    if ~strcmp(mode,'native') % all channels are put along same dimension
    %
    Z = zeros(n_channels*nBins, h, w);
        %
        for c = 1:n_channels,
            for b = 1:nBins,
                if ~single_channel
                    u = double(squeeze(bandhdata(c,b,:,:)))';                                    
                else
                    u = double(squeeze(bandhdata(b,:,:)))';
                end
                index = (c - 1)*nBins + b;
                Z(index,:,:) = u;
            end
        end;                                                    
        %
        imgId = mat2omeroImage(session, Z, pixeltype, filename,  img_description, channels_names, modulo);
        %
        link = omero.model.DatasetImageLinkI;
            link.setChild(omero.model.ImageI(imgId, false));
                link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                    session.getUpdateService().saveAndReturnObject(link);     
        image = get_Object_by_Id(session,imgId);
        %
        ome_params.SizeZ = 1;
        ome_params.SizeC = 1;
        ome_params.SizeT = 1;
        %
        SizeM = n_channels*nBins;
                switch modulo
                    case 'ModuloAlongC'
                        ome_params.SizeC = SizeM;
                    case 'ModuloAlongZ'
                        ome_params.SizeZ = SizeM;
                    case 'ModuloAlongT'
                        ome_params.SizeT = SizeM;
                end           
        %
    else % 'native' - meaning every channel goes to separte "C" with lifetimes according on "T" or "Z"

        sizeX = h;
        sizeY = w;
        sizeC = n_channels; 
        
        if strcmp(modulo,'ModuloAlongT')
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
        imgId = mat2omeroImage_native(session, data, pixeltype, filename,  img_description, channels_names);
        %
        link = omero.model.DatasetImageLinkI;
            link.setChild(omero.model.ImageI(imgId, false));
                link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                    session.getUpdateService().saveAndReturnObject(link);     
        image = get_Object_by_Id(session,imgId);
        %        
        ome_params.SizeZ = 1;
        ome_params.SizeC = sizeC;
        ome_params.SizeT = 1;
        %
        switch modulo
            case 'ModuloAlongZ'
                ome_params.SizeZ = sizeZ;
            case 'ModuloAlongT'
                ome_params.SizeT = sizeT;
        end                                   
        
    end % 'native'        
    %
%     xmlFileName = write_OME_FLIM_metadata(ome_params); 
%     %
%     namespace = 'IC_PHOTONICS';
%     description = ' ';
%     %
%     sha1 = char('pending');
%     file_mime_type = char('application/octet-stream');
%     %
%     add_Annotation(session, ...
%                         image, ...
%                         sha1, ...
%                         file_mime_type, ...
%                         xmlFileName, ...
%                         description, ...
%                         namespace);    
%     %
%     delete(xmlFileName);

        % add xml modulo annotation
        delaynums = zeros(1,numel(channels_names));
        for f=1:numel(channels_names)
            delaynums(f) = str2num(channels_names{f});
        end
        %
        xmlnode = create_ModuloAlongDOM(delaynums, [], modulo, 'TCSPC');
        add_XmlAnnotation(session,image,xmlnode,'http://www.openmicroscopy.org/Schemas/Additions/2011-09');
        %                                

end
