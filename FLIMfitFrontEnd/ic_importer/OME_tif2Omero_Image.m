function ret = OME_tif2Omero_Image(factory,filename)

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
        
    ret.imageId = [];
    ret.s = [];

    imageId = [];
    
    if isempty(factory) || isempty(filename)
        errordlg('upload_Image: bad input');
        return;
    end;                   
    
    tT = Tiff(filename);
    description = tT.getTag('ImageDescription'); %getTag accesses “native” tiff header data (bitdepth, x/y res etc.) – OME-XML data is stored in the ImageDescription field.  
    if isempty(description), return; end;  
    
    [parseResult,~] = xmlreadstring(description);
    tree = xml_read(parseResult);
    
    SizeC = tree.Image.Pixels.ATTRIBUTE.SizeC;
    SizeT = tree.Image.Pixels.ATTRIBUTE.SizeT;
    SizeZ = tree.Image.Pixels.ATTRIBUTE.SizeZ;
    
    SizeX = tree.Image.Pixels.ATTRIBUTE.SizeX;
    SizeY = tree.Image.Pixels.ATTRIBUTE.SizeY;

    counter = 0;
    max_counter = SizeC*SizeT*SizeZ;
    w = waitbar(0, [ 'Loading ' filename ]);
        
    DimensionOrder = tree.Image.Pixels.ATTRIBUTE.DimensionOrder;
    
    isBigEndian = true;
    if isfield(tree.Image.Pixels.ATTRIBUTE,'BigEndian')
        isBigEndian = strcmp(tree.Image.Pixels.ATTRIBUTE.BigEndian,'true');
    end;
                    
queryService = factory.getQueryService();
pixelsService = factory.getPixelsService();
rawPixelsStore = factory.createRawPixelsStore(); 
containerService = factory.getContainerService();

pixeltype = 'double'; % ?
if isfield(tree.Image.Pixels.ATTRIBUTE,'PixelType')
    pixeltype = tree.Image.Pixels.ATTRIBUTE.PixelType;
elseif isfield(tree.Image.Pixels.ATTRIBUTE,'Type')
    pixeltype = tree.Image.Pixels.ATTRIBUTE.Type;
end; % :)
    
% Lookup the appropriate PixelsType, depending on the type of data you have:
p = omero.sys.ParametersI();
p.add('type',rstring(pixeltype));       
q=['from PixelsType as p where p.value= :type'];
pixelsType = queryService.findByQuery(q,p);

strings1 = strrep(filename,filesep,'/');
strng = split('/',strings1);imageName = strng(length(strng));

% Use the PixelsService to create a new image of the correct dimensions:
imageId = pixelsService.createImage(SizeX, SizeY, SizeZ, SizeT, toJavaList([uint32(0:(SizeC - 1))]), pixelsType, char(imageName), char(description));

% Then you have to get the PixelsId from that image, to initialise the rawPixelsStore. I use the containerService to give me the Image with pixels loaded:
image = containerService.getImages('Image',  toJavaList(uint64(imageId.getValue())),[]).get(0);
pixels = image.getPrimaryPixels();

% physicalsize - ..WHY DOESN'T IT WORK?
%     PhysicalSizeX = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeX;
%     PhysicalSizeY = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeY;
%     PhysicalSizeZ = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ;    
%         pixels.setPhysicalSizeX(rdouble(PhysicalSizeX));
%         pixels.setPhysicalSizeY(rdouble(PhysicalSizeY));
%         pixels.setPhysicalSizeZ(rdouble(PhysicalSizeZ));
%         %pixels.save();
                
pixelsId = pixels.getId().getValue();
rawPixelsStore.setPixelsId(pixelsId, true);

min_val = Inf;
max_val = -Inf;

    switch DimensionOrder        
        case     'XYTZC'            
            for c = 1:SizeC 
                for z = 1:SizeZ
                    for t = 1:SizeT
                          set_plane(c,z,t,c,z,t,SizeZ,SizeT);                                                                        
                    end
                end
            end                         
        case     'XYTCZ'            
            for z = 1:SizeZ 
                for c = 1:SizeC
                    for t = 1:SizeT
                          set_plane(c,z,t,z,c,t,SizeC,SizeT);                        
                    end
                end
            end                         
        case     'XYZCT'            
            for t = 1:SizeT
                for c = 1:SizeC
                    for z = 1:SizeZ                  
                          set_plane(c,z,t,t,c,z,SizeC,SizeZ);                        
                    end
                end
            end                                     
        case     'XYZTC' % LaVision            
            for c = 1:SizeC 
                for t = 1:SizeT
                    for z = 1:SizeZ
                          set_plane(c,z,t,c,t,z,SizeT,SizeZ);                        
                    end
                end
            end                         
        case     'XYCTZ'            
            for z = 1:SizeZ
                for t = 1:SizeT                         
                    for c = 1:SizeC                        
                          set_plane(c,z,t,z,t,c,SizeT,SizeC);                        
                    end
                end
            end                                     
        case     'XYCZT'
            for t = 1:SizeT
                for z = 1:SizeZ                        
                    for c = 1:SizeC                        
                          set_plane(c,z,t,t,z,c,SizeZ,SizeC);                        
                    end
                end
            end                                                 
    end
%

for c = 1:SizeC 
    pixelsService.setChannelGlobalMinMax(pixelsId, c-1, min_val, max_val);                        
end;    
%
rawPixelsStore.save();
rawPixelsStore.close();
%
 RENDER = true;
re = factory.createRenderingEngine();
%
re.lookupPixels(pixelsId)
    if ~re.lookupRenderingDef(pixelsId)
        re.resetDefaults();  
    end;
    if ~re.lookupRenderingDef(pixelsId)
        errordlg('mmm... can not render properly');
        RENDER = false;
    end
%
if RENDER
    try
    % start the rendering engine
    re.load();
    % optional setting of rendering 'window' (levels)
    %renderingEngine.setChannelWindow(cIndex, float(minValue), float(maxValue))
    %
    alpha = 255;
    switch SizeC % likely RGB
        case 3
            re.setRGBA(0, 255, 0, 0, alpha);
            re.setRGBA(1, 0, 255, 0, alpha);
            re.setRGBA(2, 0, 0, 255, alpha);
        otherwise
            for c = 1:SizeC,
                re.setRGBA(c - 1, 255, 255, 255, alpha);
            end
    end
    %
    re.saveCurrentSettings();
    catch e
        disp(e);
    end
end;
    
re.close();

delete(w);
drawnow;

ret.imageId = imageId;
ret.description = description;

    function set_plane(c,z,t,l1,l2,l3,L2,L3)
                        ind = l3 + L3*( (l2-1) + L2*(l1-1) );                         
                        plane = imread(filename,'Index',ind);              
                        cur_min_val = double(min(plane(:)));
                        cur_max_val = double(max(plane(:)));
                            if cur_min_val < min_val, min_val = cur_min_val; end;
                            if cur_max_val > max_val, max_val = cur_max_val; end;
                        %if isBigEndian, plane = swapbytes(plane); end; % ???                        
                        bytear = ConvertClientToServer(pixels, plane');
                        
                        rawPixelsStore.setPlane(bytear, int32(z-1),int32(c-1),int32(t-1));                        
                        %disp([ind t-1 z-1 c-1]);                        
                        waitbar(counter/max_counter, w);
                        drawnow;
                        counter = counter + 1;
    end
end
   