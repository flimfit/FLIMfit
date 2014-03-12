function [imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session, image, varargin)

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

% USAGE EXAMPLES - OPT data
    
%[imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session,'Angle','Rot','_','fr');

% OPT SINOGRAM DATA

% [imdata, ATTRIBUTES, VALUES] = load_omero_image_stack2(session,image,'Angle');
% if ~isempty(imdata)
%     [sizerot,sizeY,sizeZ,sizeC,sizeT] = size(imdata);
%     ANGLES_USED = 360/sizerot;
%     for i=1:sizeZ
%         Sinogram = squeeze(imdata(:,:,i,sizeC,sizeT))';
%         %imagesc(Sinogram) % shows the sinogram data
%         Reconstruction = iradon(Sinogram,ANGLES_USED,'linear','Ram-Lak');
%         imagesc(Reconstruction) % shows the reconstructed plane
%         drawnow
%     end
% end

% OPT RAW DATA

% [imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session,image,'Rot');
% if ~isempty(imdata)
%     [sizeX,sizeY,n_angles,sizeC,sizeT] = size(imdata);
%     for i=1:n_angles        
%         Image = squeeze(imdata(:,:,i,sizeC,sizeT)) - 32768;
%         imagesc(Image) % shows the image plane
%         drawnow
%     end
% end


    imdata = [];
    ATTRIBUTES = []; 
    VALUES = [];    
                 
    pixelsList = image.copyPixels();    
    pixels = pixelsList.get(0);
                        
    SizeC = pixels.getSizeC().getValue();
    SizeZ = pixels.getSizeZ().getValue();
    SizeT = pixels.getSizeT().getValue();     
    SizeX = pixels.getSizeY().getValue();  
    SizeY = pixels.getSizeX().getValue();

    if (SizeZ > 1 && SizeC == 1 && SizeT ==1) || ...
       (SizeC > 1 && SizeZ == 1 && SizeT ==1) || ...
       (SizeT > 1 && SizeZ == 1 && SizeC ==1), 
       % do nothing  
    else
        errordlg('data not along single dim?.. bye..'), return,    
    end;
        
        pixelsId = pixels.getId().getValue();
        rawPixelsStore = session.createRawPixelsStore(); 
        rawPixelsStore.setPixelsId(pixelsId, false);    
            
    % imply that image has xml annotation with modulo spec, otherwise say gdbye
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
    
    if isempty(s) % try to get filenames-metadata from Description field
        
        description = image.getDescription().getValue();        
        if isempty(description), return; end;  
        [parseResult,~] = xmlreadstring(description);
        tree = xml_read(parseResult);
        tiffdata = tree.Image.Pixels.TiffData;
        
        imdata = zeros(SizeX,SizeY,SizeZ,SizeC,SizeT);

        w = waitbar(0, 'Loading images....');
        %        
        N = numel(tiffdata);
        for k = 1:N,
            fname = tiffdata(k).UUID.ATTRIBUTE.FileName; 
            z = fix(tiffdata(k).ATTRIBUTE.FirstZ); 
            c = fix(tiffdata(k).ATTRIBUTE.FirstC); 
            t = fix(tiffdata(k).ATTRIBUTE.FirstT);            
            rawPlane = rawPixelsStore.getPlane(z,c,t);                    
            plane = toMatrix(rawPlane, pixels); 
            imdata(:,:,z+1,c+1,t+1) = plane';
            waitbar(k/N,w);
            drawnow;                            
        end           
        %   
        delete(w);
        drawnow;    
        
        %%%%%%%%%%%%%%%%%%%%%%%% ATTRIBUTES
        try
            out = parse_string_for_attribute_value(tiffdata(1).UUID.ATTRIBUTE.FileName,varargin);    
            z = 0;
            for k = 1 : numel(out)
                if ~isempty(out{k})
                    z = z + 1;
                    ATTRIBUTES{z} = cellstr(out{k}.attribute);
                end
            end

            if ~exist('ATTRIBUTES','var') errordlg('nothing to look for?.. bye..'), 
                ATTRIBUTES = [];
                VALUES = [];
                return, 
            end;

            n_attr = numel(ATTRIBUTES);                
            VALUES = zeros(N,n_attr);

            for m = 1:N
                out = parse_string_for_attribute_value(tiffdata(m).UUID.ATTRIBUTE.FileName,varargin);    
                    for k = 1 : numel(out)
                        for a = 1:n_attr
                            if ~isempty(out{k}) && strcmp(ATTRIBUTES{a},out{k}.attribute)
                                VALUES(m,a) = out{k}.value;
                            end
                        end
                    end
            end                                  
        catch
            errordlg('error occurred');
                ATTRIBUTES = [];
                VALUES = [];
                return;     
        end

        %%%%%%%%%%%%%%%%%%%%%%%% ATTRIBUTES
                
    else % get it from XML annotation involving Modulo & 'Single_Plane_Image_File_Names' specifier
     
        [parseResult,~] = xmlreadstring(s);
        tree = xml_read(parseResult);
        modulo = [];        
        if isfield(tree,'ModuloAlongC')
            modulo = tree.ModuloAlongC;
            modulo_name = 'ModuloAlongC';
            N = SizeC;
        elseif isfield(tree,'ModuloAlongT')
            modulo = tree.ModuloAlongT;
            modulo_name = 'ModuloAlongT';        
            N = SizeT;        
        elseif  isfield(tree,'ModuloAlongZ')
            modulo = tree.ModuloAlongZ;
            modulo_name = 'ModuloAlongZ';        
            N = SizeZ;        
        end;  
        if isempty(modulo), errordlg('..no modulo spec?.. bye..'), return, end;        

        if isfield(modulo.ATTRIBUTE,'Description')
            if ~strcmp(modulo.ATTRIBUTE.Description,'Single_Plane_Image_File_Names'), errordlg('..no filenames spec?.. bye..'), return, end;
        end

        if isfield(modulo.ATTRIBUTE,'TypeDescription')
            if ~strcmp(modulo.ATTRIBUTE.TypeDescription,'Single_Plane_Image_File_Names'), errordlg('..no filenames spec?.. bye..'), return, end;
        end

        try
            out = parse_string_for_attribute_value(modulo.Label{1},varargin);    
            z = 0;
            for k = 1 : numel(out)
                if ~isempty(out{k})
                    z = z + 1;
                    ATTRIBUTES{z} = cellstr(out{k}.attribute);
                end
            end

            if ~exist('ATTRIBUTES','var') errordlg('nothing to look for?.. bye..'), 
                ATTRIBUTES = [];
                VALUES = [];
                return, 
            end;

            N = numel(modulo.Label);
            n_attr = numel(ATTRIBUTES);                
            VALUES = zeros(N,n_attr);

            for m = 1:N
                out = parse_string_for_attribute_value(modulo.Label{m},varargin);    
                    for k = 1 : numel(out)
                        for a = 1:n_attr
                            if ~isempty(out{k}) && strcmp(ATTRIBUTES{a},out{k}.attribute)
                                VALUES(m,a) = out{k}.value;
                            end
                        end
                    end
            end                                  
        catch
            errordlg('error occurred');
                ATTRIBUTES = [];
                VALUES = [];
                return;     
        end
            
        imdata = zeros(SizeX,SizeY,SizeZ,SizeC,SizeT);
        %
        w = waitbar(0, 'Loading images....');
        %
        z = 0;
        c = 0;
        t = 0;
        for k = 1:N,
            switch modulo_name
                case 'ModuloAlongZ' 
                    z = k-1;
                case 'ModuloAlongC' 
                    c = k-1;                    
                case 'ModuloAlongT' 
                    t = k-1;                                        
            end
            rawPlane = rawPixelsStore.getPlane(z,c,t);                    
            plane = toMatrix(rawPlane, pixels); 
            imdata(:,:,z+1,c+1,t+1) = plane';
            %
            waitbar(k/N,w);
            drawnow;                
        end

        delete(w);
        drawnow;    

        rawPixelsStore.close();           
                                            
    end
            
    function out = parse_string_for_attribute_value(string,specs)

    out = [];

    NN = length(string);

        for kk = 1 : numel(specs)

            tok = specs{kk};
            toklen = length(tok); 

            startind = strfind(string,tok) + toklen;

            %fr000Rot325_0000.tif
            vallen = 0;
            for mm = startind : NN    
                if ~isempty(regexp(string(mm),'\d','once'))
                    vallen = vallen + 1;
                else
                    break, 
                end;            
            end

            endind = startind + vallen - 1; 

            try
                val = str2num(string(startind:endind));
            catch
            end;

            out{kk} = [];
            if exist('val','var') && ~isempty(val)
                out{kk}.attribute = tok;
                out{kk}.value = val;
                clear('val');
            end

        end

    end
    
end
