function imageId = upload_OPT_dir_as_Omero_Image(session,dataset,folder,extension)

settingnames = {'modulo' 'type' 'unit' 'values' 'Start' 'Step' 'End' 'description' 'namespace'};

                  if strcmp(extension,'tif') || strcmp(extension,'tiff')
                    files = dir([folder filesep '*.' 'tif*']);
                  else
                    files = dir([folder filesep '*.' extension]);
                  end
                  %
                  num_files = length(files);
                  if 0==num_files
                    errordlg('No suitable files in the directory');
                    return;
                  end;
                  
                  file_names = cell(1,num_files);
                  for i=1:num_files
                      file_names{i} = files(i).name;
                  end
                  file_names = sort_nat(file_names);
                                                          
        filenames = strrep(file_names,'.tif','');

        start_Rot = regexp(filenames,'Rot'); % rotation                   
        start_frame = regexp(filenames,'fr'); % frame
        start_lifetime = regexp(filenames,'_'); % lifetime
        
        there_is_angle_info = ~(sum(cellfun(@isempty,start_Rot))==num_files);
        there_is_frame_info = ~(sum(cellfun(@isempty,start_frame))==num_files);
        there_is_lifetime_info = ~(sum(cellfun(@isempty,start_lifetime))==num_files);
        
        rot_len = 3;
        fr_len = 3;
        lf_len = 4;
        
if there_is_angle_info        
                    for i = 1 : num_files    
                        str = filenames{i};
                        strot = start_Rot{i}+3;
                        enrot = strot+rot_len-1;
                        angles(i) = str2num(str(strot:enrot));
                    end
end

if there_is_frame_info
                    for i = 1 : num_files    
                        str = filenames{i};
                        stfr = start_frame{i}+2;
                        enfr = stfr+fr_len-1;
                        frames(i) = str2num(str(stfr:enfr));
                    end
end

if there_is_lifetime_info
                    for i = 1 : num_files    
                        str = filenames{i};    
                        stlf = start_lifetime{i}+1;
                        enlf = stlf+lf_len-1;
                        lifetimes(i) = str2num(str(stlf:enlf));
                    end
end

if 0==sum(angles), there_is_angle_info = false; end;
if 0==sum(frames), there_is_frame_info = false; end;
if 0==sum(lifetimes), there_is_lifetime_info = false; end;

% there_is_angle_info
% there_is_frame_info
% there_is_lifetime_info

there_is_camera_info = false;

description_data = [];

N_Camera_S = 1;
N_Frame_S = 1;

N_Excitation_S = 1;
N_Emission_S = 1;
N_Macro_time_S = 1;

N_Z = 1;
N_C = N_Emission_S; % native
N_T = 1;

% Z
if there_is_camera_info
    N_Camera_S = 1; % ;) 
    description_data{1} = struct;
    description_data{1}.(settingnames{1}) = 'ModuloAlongZ';
    description_data{1}.(settingnames{2}) = 'camera';
    description_data{1}.(settingnames{3}) = 'number';
    description_data{1}.(settingnames{4}) = [ ];
    description_data{1}.(settingnames{5}) = '1';
    description_data{1}.(settingnames{6}) = '1';
    description_data{1}.(settingnames{7}) = num2str(N_Camera_S);
    description_data{1}.(settingnames{8}) = ' ';
    description_data{1}.(settingnames{9}) = ' ';
else
    description_data{1} = [];
end
    
% Z
if there_is_frame_info
    N_Frame_S = max(frames); 
    % Z
    description_data{2} = struct;
    description_data{2}.(settingnames{1}) = 'ModuloAlongZ';
    description_data{2}.(settingnames{2}) = 'frame';
    description_data{2}.(settingnames{3}) = 'number';
    description_data{2}.(settingnames{4}) = [ ];
    description_data{2}.(settingnames{5}) = '1';
    description_data{2}.(settingnames{6}) = '1';
    description_data{2}.(settingnames{7}) = N_Frame_S;
    description_data{2}.(settingnames{8}) = ' ';
    description_data{2}.(settingnames{9}) = ' ';    
else
    description_data{2} = [];
end

% Z
if there_is_angle_info
    N_Angle_S = numel(angles);
    Start_Angle = angles(1); 
    Step_Angle = angles(2)-angles(1); 
    End_Angle = angles(N_Angle_S);
    % Z
    description_data{3} = struct;
    description_data{3}.(settingnames{1}) = 'ModuloAlongZ';
    description_data{3}.(settingnames{2}) = 'angle';
    description_data{3}.(settingnames{3}) = 'degree';
    description_data{3}.(settingnames{4}) = [ ];
    description_data{3}.(settingnames{5}) = num2str(Start_Angle);
    description_data{3}.(settingnames{6}) = num2str(Step_Angle);
    description_data{3}.(settingnames{7}) = num2str(End_Angle);
    description_data{3}.(settingnames{8}) = [ ];
    description_data{3}.(settingnames{9}) = [ ];    
else
    description_data{3} = [ ];
end;

node = com.mathworks.xml.XMLUtils.createDocument('Modulo');

for m = 1:numel(description_data)
           
    if ~isempty(description_data{m})
        
       namespace = description_data{m}.namespace;
                                    
       if isempty(namespace)
           namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';
       end
        
       Modulo = node.getDocumentElement;     
       Modulo.setAttribute('namespace',namespace);
     
       ModuloAlong = node.createElement(description_data{m}.modulo);                                
       ModuloAlong.setAttribute('Type',description_data{m}.type);
       ModuloAlong.setAttribute('Unit',description_data{m}.unit);       
       ModuloAlong.setAttribute('Description',description_data{m}.description);

       if isempty(description_data{m}.values) % start step end           
           ModuloAlong.setAttribute('Start',description_data{m}.Start); 
           ModuloAlong.setAttribute('Step',description_data{m}.Step);
           ModuloAlong.setAttribute('End',description_data{m}.End);
       else

           vals = description_data{m}.values;           
           for i=1:length(vals)
                thisElement = node.createElement('Label'); 
                thisElement.appendChild(node.createTextNode(num2str(vals{i})));
                ModuloAlong.appendChild(thisElement);
           end           
           
       end;                                       
                                       
      Modulo.appendChild(ModuloAlong);
      
    end
end

SizeZ = N_Z*N_Angle_S*N_Camera_S*N_Frame_S;
SizeC = N_C*N_Excitation_S*N_Emission_S;
SizeT = N_Macro_time_S; %numel(macro_time); %*(End_Lifetime - Start_Lifetime + 1)/Step_Lifetime
SizeX = [];
SizeY = [];
    
queryService = session.getQueryService();
pixelsService = session.getPixelsService();
rawPixelsStore = session.createRawPixelsStore(); 
containerService = session.getContainerService();

    hw = waitbar(0, 'Loading OPT data...');
                    for i = 1 : num_files    
                        
                        angle = angles(i);
                        frame = frames(i);
                        lifetime = lifetimes(i);
                                                                              
                        U = imread([folder filesep file_names{i}],extension);
                                                  
                        if isempty(SizeX)
                            [w,h] = size(U);
                            SizeX = w;
                            SizeY = h;  
                            %
                            imageName = folder;
                            img_description = ' ';               
                            pixeltype = get_num_type(U);                        
                            %
                            % Lookup the appropriate PixelsType, depending on the type of data you have:
                            p = omero.sys.ParametersI();
                            p.add('type',rstring(pixeltype));       
                            q=['from PixelsType as p where p.value= :type'];
                            pixelsType = queryService.findByQuery(q,p);

                            % Use the PixelsService to create a new image of the correct dimensions:
                            iId = pixelsService.createImage(SizeX, SizeY, SizeZ, SizeT, toJavaList([uint32(0:(SizeC - 1))]), pixelsType, imageName, img_description);
                            imageId = iId.getValue();

                            % Then you have to get the PixelsId from that image, to initialise the rawPixelsStore. I use the containerService to give me the Image with pixels loaded:
                            image = containerService.getImages('Image',  toJavaList(uint64(imageId)),[]).get(0);
                            pixels = image.getPrimaryPixels();
                            pixelsId = pixels.getId().getValue();
                            rawPixelsStore.setPixelsId(pixelsId, true); 
                            %
                        end    
                        
                        plane = U;   
                        bytear = ConvertClientToServer(pixels, plane);
                        
                        if there_is_angle_info && ~there_is_frame_info && ~there_is_lifetime_info
                            rawPixelsStore.setPlane(bytear, int32(i-1),int32(0),int32(0)); % Z! - Z,C,T
                        end                        
                        %
                        waitbar(i/num_files,hw);
                        drawnow;
                        %                                                       
                    end
                    
                    delete(hw);
                    drawnow;                 
                    
                    link = omero.model.DatasetImageLinkI;
                    link.setChild(omero.model.ImageI(imageId, false));
                    link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                    session.getUpdateService().saveAndReturnObject(link);                                                                             
                        
                    id = java.util.ArrayList();
                    id.add(java.lang.Long(imageId)); %id of the image
                    containerService = session.getContainerService();
                    list = containerService.getImages('Image', id, omero.sys.ParametersI());
                    image = list.get(0);
                    % 
                    add_XmlAnnotation(session,[],image,node);
                                                                                                  
end                    