function [imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session, varargin)

    imdata = [];
    
    userid = session.getAdminService().getEventContext().userId;

    [ dataset, ~ ] = select_Dataset(session,userid,'Select a Dataset:');
    if isempty(dataset), return, end;
    image = select_Image(session,userid,dataset);
    if isempty(image), return, end;
             
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
        
    % imply that image has xml annotation with modulo spec, otherwise say gdbye
    s = read_XmlAnnotation_havingNS(session,image,'openmicroscopy.org/omero/dimension/modulo'); 
    if isempty(s), errordlg('..no annotation? .. bye..'), return, end;
     
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

    pixelsId = pixels.getId().getValue();
    rawPixelsStore = session.createRawPixelsStore(); 
    rawPixelsStore.setPixelsId(pixelsId, false);    
        
    imdata = zeros(N,SizeX,SizeY);
    
    w = waitbar(0, 'Loading images....');
    %
    for k = 1:N,
        switch modulo_name
            case 'ModuloAlongZ' 
                rawPlane = rawPixelsStore.getPlane(k - 1, 0, 0 );        
            case 'ModuloAlongC' 
                rawPlane = rawPixelsStore.getPlane(0, k - 1, 0);                        
            case 'ModuloAlongT' 
                rawPlane = rawPixelsStore.getPlane(0, 0, k - 1);        
        end
        %
        plane = toMatrix(rawPlane, pixels); 
        imdata(k,:,:) = plane';
        %
        waitbar(k/N,w);
        drawnow;                
    end
    
    delete(w);
    drawnow;    
    
    rawPixelsStore.close();              
    
end