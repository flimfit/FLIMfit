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

% USAGE EXAMPLE - 
%{

clear all;

addpath_global_analysis();     

if exist('omero_settings.xml','file') 
    [ settings, ~ ] = xml_read ('omero_settings.xml');    
    logon = settings.logon;
else
    logon = OMERO_logon();
end
    client = loadOmero(logon{1});
    %client.enableKeepAlive(60); 
                
    try 
        session = client.createSession(logon{2},logon{3});
    catch ME
        client = [];
        session = [];
        disp(ME);
        errordlg('Error creating OMERO session');
    end            
    
%[imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session,'Angle','Rot','_','fr');

% % OPT SINOGRAM DATA
% 
% [imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session,'Angle');
% if ~isempty(imdata)
%     [sizeY, sizeX, sizerot] = size(imdata);
%     ANGLES_USED = 360/sizerot;
%     for i=1:sizeY    
%         Sinogram = squeeze(imdata(i,:,:));
%         %imagesc(Sinogram) % shows the sinogram data
%         Reconstruction = iradon(Sinogram,ANGLES_USED,'linear','Ram-Lak');
%         imagesc(Reconstruction) % shows the reconstructed plane
%         drawnow
%     end
% end

% OPT RAW DATA

[imdata, ATTRIBUTES, VALUES] = load_omero_image_stack(session,'Rot');
if ~isempty(imdata)
    [n_angles,sizeX,sizeY] = size(imdata);
    for i=1:n_angles    
        Image = squeeze(imdata(i,:,:)) - 32768;
        imagesc(Image) % shows the reconstructed plane
        drawnow
    end
end
% 
% if ~exist('omero_settings.xml','file') 
%     omero_settings = [];
%     omero_settings.logon = logon;
%     xml_write('omero_settings.xml',omero_settings);
% end

client.closeSession();
clear all;
unloadOmero();

%}   