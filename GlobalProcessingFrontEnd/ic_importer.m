function ic_importer()
%
addpath_global_analysis();        
%
settings = [];
%
if exist('ic_importer_settings.xml','file') 
    [ settings ~ ] = xml_read ('ic_importer_settings.xml');    
    logon = settings.logon;
else
    logon = OMERO_logon();
end
%
data = createData();
    gui = createInterface(data);
        updateInterface();    
%
%-------------------------------------------------------------------------%
    function data = createData()
        %
        data.main_well_plate_annotation_sacred_filename = 'plate_reader_metadata.xml';
        %
        if ~isempty(settings)
            data.DefaultDataDirectory = settings.DefaultDataDirectory;        
            data.image_annotation_file_extension = settings.image_annotation_file_extension;        
            data.load_dataset_annotations = settings.load_dataset_annotations;
            data.modulo = settings.modulo;
            data.native_multichannel_FLIM = settings.native_multichannel_FLIM;            
        else
            data.DefaultDataDirectory = 'c:\';        
            data.image_annotation_file_extension = 'none';        
            data.load_dataset_annotations = false;
            data.modulo = 'ModuloAlongT';
            data.native_multichannel_FLIM = false;
        end                    
        %
        data.client  = [];
        data.session  = [];            
        data.project = [];            
        %
        data.Directory = [];
        data.ProjectName = [];
        %
        data.extension = '???';
        data.LoadMode = '???';  
        data.SingleFileMeaningLabel = '???';
        %
        %        
        data.dirlist = []; % list of directories to import for well plate
        data.dataset_annotations = [];                          
    end % createData
%-------------------------------------------------------------------------%
    function gui = createInterface( data )
        %
        bckg_color = [.8 .8 .8];
        %
        gui = struct();
        % Open a window and add some menus
        gui.Window = figure( ...
            'Name', 'Imperial College Omero Importer', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ... % 
            'Position', [280 678 970 120], ... % ??? 'Position', [680 678 560 420], ...
            'Toolbar', 'none', ...
            'DockControls', 'off', ...
            'Resize', 'off', ...
            'Color',bckg_color, ...
            'HandleVisibility', 'off' );
        %
        set(gui.Window,'CloseRequestFcn',@onExit);
        %                
        % + File menu
        gui.menu_file = uimenu( gui.Window, 'Label', 'File' );
        uimenu( gui.menu_file, 'Label','Set data directory', 'Callback', @onSetDirectory );
        
        gui.menu_file_set_single = uimenu(gui.menu_file,'Label','Set image');
        gui.handles.menu_file_single_irf = uimenu(gui.menu_file_set_single,'Label','irf', 'Callback', @onSetFile);
        gui.handles.menu_file_single_bckg = uimenu(gui.menu_file_set_single,'Label','background', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_tbckg = uimenu(gui.menu_file_set_single,'Label','time_varying_background', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_intref = uimenu(gui.menu_file_set_single,'Label','intensity_reference', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_Gfctr = uimenu(gui.menu_file_set_single,'Label','g_factor', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_Gfctr = uimenu(gui.menu_file_set_single,'Label','sample', 'Callback', @onSetFile);        
                      
        uimenu( gui.menu_file, 'Label', 'Exit', 'Callback', @onExit );        
        % + Omero menu
        gui.menu_omero = uimenu( gui.Window, 'Label', 'Omero' );
        gui.menu_logon = uimenu( gui.menu_omero, 'Label', 'Set logon default', 'Callback', @onLogon );        
        gui.menu_setproject = uimenu( gui.menu_omero, 'Label','Set Project', 'Callback', @onSetDestination );
        gui.menu_setdataset = uimenu( gui.menu_omero, 'Label','Set Dataset', 'Callback', @onSetDestination );
        gui.menu_setproject = uimenu( gui.menu_omero, 'Label','Set Screen', 'Callback', @onSetDestination );        
        % + Upload menu
        %gui.menu_upload      = uimenu(gui.Window,'Label','Upload');
        %uimenu(gui.menu_upload,'Label','Go','Accelerator','G','Callback', @onGo);                                
        
        gui.menu_upload      = uimenu(gui.Window,'Label',data.modulo);
        uimenu(gui.menu_upload,'Label','ModuloAlongC','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongT','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongZ','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongT (multichannel sdt)','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongZ (multichannel sdt)','Callback', @onSetModuloAlong);                                        
                        
        %
        % CONTROLS
        gui.ProjectNamePanel = uicontrol( 'Style', 'text','Parent',gui.Window,'String',data.ProjectName,'FontSize',10,'Position',[20 80 800 20],'BackgroundColor',bckg_color);          
        %
        gui.DirectoryNamePanel = uicontrol( 'Style', 'text', 'Parent',gui.Window,'String',data.Directory,'FontSize',10,'Position',[20 60 800 20],'BackgroundColor',bckg_color);
        %
        gui.GoButton = uicontrol('Style', 'PushButton','Parent',gui.Window,'String','Go',...
             'Position',[20 20 100 20 ],'Callback', @onGo,'FontSize',10);
        %                          
        gui.Indicator = uicontrol('Style','text','Parent',gui.Window, 'BackgroundColor','red','Position',[150 20 100 20],'String',data.extension,'FontSize',10);
        %
        gui.ImageAnnotationFileExtensionPrompt = uicontrol( 'Style', 'text', ...
            'Parent',gui.Window, ...
            'String','Image annotation file extension', ...
            'BackgroundColor',bckg_color, ...
            'FontSize',10, ...
            'Position',[270 20 350 20]);
        %    
        gui.ImageAnnotationFileExtensionPopup = uicontrol('Parent',gui.Window,'Style', 'popup',...
            'String', 'none|xml|txt|xls|csv',...
            'FontSize',10, ...
            'Position', [540 20 70 24],...
            'BackgroundColor',bckg_color, ...           
            'Callback', @SetImageAnnotationFileExtension);
        %

        
        gui.DatasetAnnotationsCheckboxPrompt = uicontrol( 'Style', 'text', ...
            'Parent',gui.Window, ...
            'String','load common files as Dataset annotations', ...
            'BackgroundColor',bckg_color, ...
            'FontSize',10, ...
            'Position',[640 20 350 20]);
        %    
        gui.DatasetAnnotationsCheckbox = uicontrol('Parent',gui.Window,'Style', 'Checkbox',...
            'FontSize',10, ...
            'Position', [940 20 70 24],...
            'BackgroundColor',bckg_color, ...           
            'Callback', @SetDatasetAnnotationsCheckbox);
        %
                               
    end % createInterface
%-------------------------------------------------------------------------%
    function updateInterface()
        %
        if isempty(data.client)
            load_omero();      
                   if isempty(data.client)
                       onExit();
                       return;
                   end;
        end;        
        %
        % indicator panel
        Color = 'red';
        if ~isempty(data.Directory) && ~isempty(data.ProjectName) && ~strcmp('???',data.extension)          
                Color = 'green';
        end
        set(gui.Indicator,'BackgroundColor',Color,'String',data.extension);
        set(gui.ProjectNamePanel,'String',data.ProjectName);
        set(gui.DirectoryNamePanel,'String',data.Directory);            
        %                        
        if strcmp(data.image_annotation_file_extension,'none')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',1);
        elseif strcmp(data.image_annotation_file_extension,'xml')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',2);
        elseif strcmp(data.image_annotation_file_extension,'txt')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',3);
        elseif strcmp(data.image_annotation_file_extension,'xls')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',4);
        elseif strcmp(data.image_annotation_file_extension,'csv')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',5);
        end                                                
        %
        %checkbox
        if data.load_dataset_annotations 
            set(gui.DatasetAnnotationsCheckbox,'Value',1);
        else
            set(gui.DatasetAnnotationsCheckbox,'Value',0);
        end
        %
        multiple_data_controls_visibility = 'on';
        %
        if strcmp('single file',data.LoadMode)
            multiple_data_controls_visibility = 'off';
        end
        %
        set(gui.ImageAnnotationFileExtensionPrompt, 'Visible', multiple_data_controls_visibility);
        set(gui.ImageAnnotationFileExtensionPopup, 'Visible', multiple_data_controls_visibility);
        set(gui.DatasetAnnotationsCheckboxPrompt, 'Visible', multiple_data_controls_visibility);
        set(gui.DatasetAnnotationsCheckbox, 'Visible', multiple_data_controls_visibility);
        %
        if data.native_multichannel_FLIM
            if strcmp(data.modulo,'ModuloAlongT')
                set(gui.menu_upload,'Label','ModuloAlongT (multichannel sdt)');     
            elseif strcmp(data.modulo,'ModuloAlongZ')                
                set(gui.menu_upload,'Label','ModuloAlongZ (multichannel sdt)');                 
            end;
        end
            
    end % updateInterface
%-------------------------------------------------------------------------%
    function onExit(~,~)
        %        
        if ~isempty(data.client)
            disp('Closing OMERO session');                
            data.client.closeSession();                
                save_settings();
        end        
        %
        delete(gui.Window);
            clear('gui');                 
                clear('data');                             
                    unloadOmero();                        
    end % onExit
%-------------------------------------------------------------------------%
    function onSetDirectory(~,~)     
        %
        data.Directory = uigetdir(data.DefaultDataDirectory,'Select the folder containing the data');     
        %
        if 0 ~= data.Directory
            %
            data.DefaultDataDirectory = data.Directory;            
            set_directory_info();            
            updateInterface();
            %            
            if isempty(data.project) || strcmp(whos_Object(data.session,data.project.getId().getValue()),'Dataset')
                % doopredelaem
                prjct = select_Project(data.session,'Select Project');
                if ~isempty(prjct)
                    data.project = prjct;
                    data.ProjectName = char(java.lang.String(data.project.getName().getValue()));
                else
                    clear_settings();
                    return;
                end;
            end
            %                        
            updateInterface();
        end        
    end % onSetDirectory
%-------------------------------------------------------------------------%
    function onLogon(~,~)  
        %
        logon = OMERO_logon;
        data.client.closeSession();                        
        delete(gui.Window);
            clear('gui');                 
                clear('data');                             
        %
        load_omero();
        %
        if ~isempty(data.client)
            data = createData();
                gui = createInterface(data);        
                    updateInterface();
        end;
    end % onLogon
%-------------------------------------------------------------------------%
    function onSetDestination(hObj,~,~)
                
        label = get(hObj,'Label');

        if strcmp(label,'Set Screen')        
            scrn = select_Screen(data.session,'Select screen');
            if ~isempty(scrn)
                data.project = scrn; 
                data.ProjectName = char(java.lang.String(data.project.getName().getValue()));                
            else
                return;
            end
            %
            if isempty(data.Directory) || ~isdir(data.Directory)
                onSetDirectory();
            end                    
                
        elseif strcmp(label,'Set Project')
            
            prjct = select_Project(data.session,'Select Project');             
            if ~isempty(prjct)
                data.project = prjct; 
                data.ProjectName = char(java.lang.String(data.project.getName().getValue()));                
            else
                return;
            end
            %
            if isempty(data.Directory) || ~isdir(data.Directory)
                onSetDirectory();
            end
            %
        else % need to set Dataset

            if isdir(data.Directory)
                errordlg('please first choose an image you want to upload');
                return;
            end
                        
            [ dtst prjct ] = select_Dataset(data.session,'Select Dataset');
            
            if ~isempty(dtst)
                data.project = dtst; % in  reality, dataset not project;
                data.ProjectName = char(java.lang.String(data.project.getName().getValue()));
            else
                return;
            end;           
            %                        
        end                   
        %
        updateInterface();

    end % onSetProject
%-------------------------------------------------------------------------%
    function onGo(~,~)
        %
        if isempty(data.Directory) || isempty(data.project)
            errordlg('either directory or project not set properly - can not continue');
            return;
        end
        %        
        strings  = split(filesep,data.Directory);
        new_dataset_name = char(strings(length(strings)));
        %  
        if ~strcmp(data.LoadMode,'single file')
            if strcmp('Dataset',whos_Object(data.session,data.project)) && ~is_Dataset_name_unique(data.project,new_dataset_name)
                errordlg('new Dataset name isn not unique - can not contuinue');
                clear_settings;
                updateInterface;     
                return;
            end        
        end;
        %        
        set(gui.Indicator,'String','..uploading..');
        %
        if (strcmp(data.extension,'tif') || strcmp(data.extension,'tiff') || strcmp(data.extension,'sdt')) && strcmp(data.LoadMode,'general')
            % simple case                 
            if data.native_multichannel_FLIM
                native_spec = 'native';
            else
                native_spec = 'whatever';
            end;
            %
            new_dataset_id = upload_dir_as_Dataset(data.session,data.project,data.Directory,data.extension,data.modulo,native_spec);
            new_dataset = get_Object_by_Id(data.session,new_dataset_id);
            %                        
            % IMAGE ANNOTATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% (this is ugly)
            if ~strcmp(data.image_annotation_file_extension,'none')
                proxy = data.session.getContainerService();
                %Set the options
                param = omero.sys.ParametersI();
                %
                param.leaves();
                %
                userId = data.session.getAdminService().getEventContext().userId; %id of the user.
                param.exp(omero.rtypes.rlong(userId));
                projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
                %
                for j = 0:projectsList.size()-1,
                    p = projectsList.get(j);
                    pid = java.lang.Long(p.getId().getValue());                
                    datasetsList = p.linkedDatasetList;
                    for i = 0:datasetsList.size()-1,                     
                         d = datasetsList.get(i);
                         did = java.lang.Long(d.getId().getValue());
                         imageList = d.linkedImageList;
                         for k = 0:imageList.size()-1,                       
                             img = imageList.get(k);                         
                             if pid == data.project.getId().getValue() && did == new_dataset_id
                                attach_file_with_same_name_if_in_the_directory(img,data.image_annotation_file_extension,data.Directory); 
                             end
                         end 
                    end;
                end;                                    
            end;
            % IMAGE ANNOTATIONS - ENDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            %
        elseif strcmp(data.LoadMode,'well plate')
            
            FOV_name_parse_func = get_Plate_param_func_name_from_metadata_xml_file( ...
                [data.Directory filesep data.main_well_plate_annotation_sacred_filename]);
            %            
            new_dataset_id = upload_PlateReader_dir(data.session, data.project, data.Directory, FOV_name_parse_func, data.modulo);
            new_dataset = get_Object_by_Id(data.session,new_dataset_id);
            
        elseif strcmp(data.LoadMode,'single file')

                        if is_OME_tif(data.Directory)
                            upload_Image_OME_tif(data.session,data.project,data.Directory,' ');                            
                        elseif ~strcmp('sdt',data.extension)
                            U = imread(data.Directory,data.extension);
                            %
                            pixeltype = get_num_type(U);
                            %                                                        
                            str = split(filesep,data.Directory);
                            file_name = str(length(str));
                            %
                            % rearrange planes
                            [w,h,Nch] = size(U);
                            Z = zeros(Nch,h,w);
                            for c = 1:Nch,
                                Z(c,:,:) = squeeze(U(:,:,c))';
                            end;
                            img_description = ' ';
                            imageId = mat2omeroImage(data.session, Z, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                            link = omero.model.DatasetImageLinkI;
                            link.setChild(omero.model.ImageI(imageId, false));
                            link.setParent(omero.model.DatasetI(data.project.getId().getValue(), false)); % in this case, "project" is Dataset
                            data.session.getUpdateService().saveAndReturnObject(link); 
                            %
                            % OME ANNOTATION
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.BigEndian = 'true';
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.DimensionOrder = 'XYCTZ'; % does not matter
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.ID = '?????';
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.PixelType = pixeltype;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeX = h; % :)
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeY = w;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = 1;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = Nch;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = 1;
                            %
                            flimXMLmetadata.Image.ContentsType = cellstr(data.SingleFileMeaningLabel);
                            %
                            xmlFileName = [tempdir 'metadata.xml'];
                            xml_write(xmlFileName,flimXMLmetadata);
                            %
                            namespace = 'IC_PHOTONICS';
                            description = ' ';
                            %
                            sha1 = char('pending');
                            file_mime_type = char('application/octet-stream');
                            %
                            add_Annotation(data.session, ...
                                            get_Object_by_Id(data.session,imageId), ...
                                            sha1, ...
                                            file_mime_type, ...
                                            xmlFileName, ...
                                            description, ...
                                            namespace);    
                            %
                            delete(xmlFileName);
                            %                            
                        else % strcmp('sdt',data.extension)
                            if data.native_multichannel_FLIM
                                native_spec = 'native';
                            else
                                native_spec = 'whatever';
                            end;
                            upload_Image_BH(data.session, data.project, data.Directory, data.SingleFileMeaningLabel, data.modulo, native_spec);
                        end                        
        end % strcmp(data.LoadMode,'single file')
        %      
        if data.load_dataset_annotations
            for k=1:numel(data.dataset_annotations)
                    %
                    namespace = 'IC_PHOTONICS';
                    description = ' ';
                    %
                    sha1 = char('pending');
                    file_mime_type = char('application/octet-stream');
                    %
                    add_Annotation(data.session, ...
                        new_dataset, ...
                        sha1, ...
                        file_mime_type, ...
                        data.dataset_annotations{k}, ...
                        description, ...
                        namespace);    
            end        
        end % if data.load_dataset_annotations
        %
        clear_settings;
        updateInterface;        
    end % onGo
%-------------------------------------------------------------------------%
    function load_omero()
        try
            data.client = loadOmero(logon{1});
            data.session = data.client.createSession(logon{2},logon{3});
        catch
            data.client = [];
            data.session = [];
            errordlg('Error creating OMERO session');        
        end
    end % load_omero
%-------------------------------------------------------------------------%           
    function set_directory_info()
        % annotations first
        annotations = [];
        % check dataset annotations..
        annotations_extensions = {'xml' 'txt' 'rtf' 'doc' 'docx' 'ppt' 'pdf' 'xls' 'xlsx' 'm' 'irf'};
        for k=1:numel(annotations_extensions)
            files = dir([data.Directory filesep '*.' annotations_extensions{k}]);
            num_files = length(files);
                if 0 ~= num_files
                    annotations = [annotations; files];
                end
        end                        
        % fill the list of annotations
        data.dataset_annotations = [];
        for k=1:numel(annotations)
            data.dataset_annotations{k} = [data.Directory filesep annotations(k).name]; %full name
            % disp(data.dataset_annotations{k});
        end                
        %
        data.extension = '???';
        data.LoadMode = '???';        
        extensions = {'tif' 'tiff' 'sdt'};
        for k=1:numel(extensions)
            files = dir([data.Directory filesep '*.' extensions{k}]);
            num_files = length(files);
                if 0 ~= num_files
                    data.extension = extensions{k};
                    data.LoadMode = 'general';   
                    return;
                end
        end              
        %                        
        % it might be well-plate data...        
        data.dirlist = [];
        totlist = dir(data.Directory);
        z = 0;
        for k=3:length(totlist)
            if 1==totlist(k).isdir
                z=z+1;
                data.dirlist{z}=[data.Directory filesep totlist(k).name];
            else
                if strcmp(totlist(k).name,data.main_well_plate_annotation_sacred_filename)
                    data.extension = 'tif'; % this is bad
                    data.LoadMode = 'well plate'; 
                end;
            end
        end   
    end % set_directory_info
%-------------------------------------------------------------------------%
    function clear_settings()
        data.Directory = [];
        data.ProjectName = [];
        data.project = [];        
        %
        data.extension = '???';
        data.LoadMode = '???';        
        data.SingleFileMeaningLabel = '???';
        %
        data.dirlist = []; % list of directories to import for well plate
        data.dataset_annotations = [];                 
    end % clear_settings
%-------------------------------------------------------------------------%  
    function save_settings()        
        ic_importer_settings = [];
        ic_importer_settings.logon = logon;
        ic_importer_settings.DefaultDataDirectory = data.DefaultDataDirectory;        
        ic_importer_settings.image_annotation_file_extension = data.image_annotation_file_extension;
        ic_importer_settings.load_dataset_annotations = data.load_dataset_annotations;
        ic_importer_settings.modulo = data.modulo;
        ic_importer_settings.native_multichannel_FLIM = data.native_multichannel_FLIM;
        xml_write('ic_importer_settings.xml', ic_importer_settings);
    end % save_settings
%-------------------------------------------------------------------------%  
    function attach_file_with_same_name_if_in_the_directory(obj,extension,directory)
        %disp(obj.getName().getValue());
        filename_with_extension = char(java.lang.String(obj.getName().getValue()));
        str = split('.',filename_with_extension);
        filename = [char(directory) filesep char(str(1)) '.' extension];
        if exist(filename,'file')
            disp(filename);            
                %
                namespace = 'IC_PHOTONICS';
                description = ' ';
                %
                sha1 = char('pending');
                file_mime_type = char('application/octet-stream');
                %
                add_Annotation(data.session, ...
                    obj, ...
                    sha1, ...
                    file_mime_type, ...
                    filename, ...
                    description, ...
                    namespace);                                        
        end        
    end
%-------------------------------------------------------------------------%  
    function SetImageAnnotationFileExtension(hObj,~)
        val = get(hObj,'Value'); % 'none|xml|txt|xls|csv'
        if val ==1
          data.image_annotation_file_extension = 'none';  
        elseif val == 2
            data.image_annotation_file_extension = 'xml'; 
        elseif val == 3
            data.image_annotation_file_extension = 'txt';  
        elseif val == 4
            data.image_annotation_file_extension = 'xls';  
        elseif val == 5
            data.image_annotation_file_extension = 'csv'; 
        end        
    end
%-------------------------------------------------------------------------%  
    function SetDatasetAnnotationsCheckbox(hObj,~,~)
        if (get(hObj,'Value') == get(hObj,'Max'))
            data.load_dataset_annotations = true;
        else
            data.load_dataset_annotations = false;
        end
    end
%-------------------------------------------------------------------------%  
    function onSetFile(hObj,~,~)
        %
        [filename, pathname] = uigetfile({'*.tif';'*.tiff';'*.sdt'},'Select File',data.DefaultDataDirectory);
        %
        if isequal(filename,0)
            return
        end
        %
        full_file_name = [pathname filesep filename]; % works;
        % check if file is OK - extension...
        str = split('.',full_file_name);
        extension = str{length(str)};
        %
        if strcmp(extension,'tif') || strcmp(extension,'tiff') || strcmp(extension,'sdt') 
                                  
            if isempty(data.project) || strcmp(whos_Object(data.session,data.project.getId().getValue()),'Project')
                % doopredelaem
                [ dtst ~ ] = select_Dataset(data.session,'Select Dataset');
                if ~isempty(dtst)
                    data.project = dtst; % in  reality, dataset not project;
                    data.ProjectName = char(java.lang.String(data.project.getName().getValue()));
                else
                    return;
                end;
            end
            %
            data.extension = extension;
            data.SingleFileMeaningLabel  = get(hObj,'Label');  
            data.LoadMode = 'single file';
            data.Directory = full_file_name;
            data.load_dataset_annotations = false;                                             
        end
        %
        updateInterface();                   
    end

    function onSetModuloAlong(hObj,~,~)
        label = get(hObj,'Label');
        if strcmp(label,'ModuloAlongT (multichannel sdt)')
            data.modulo = 'ModuloAlongT';
            data.native_multichannel_FLIM = true;
        elseif strcmp(label,'ModuloAlongZ (multichannel sdt)')
            data.modulo = 'ModuloAlongZ';
            data.native_multichannel_FLIM = true;
        else
            data.modulo  = label;    
            data.native_multichannel_FLIM = false;
        end;                        
      set(gui.menu_upload,'Label',label);      
      updateInterface();                   
    end


end % EOF
