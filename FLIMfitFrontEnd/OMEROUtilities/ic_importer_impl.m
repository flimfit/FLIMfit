classdef ic_importer_impl < handle
        
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
            
    properties
        
        window;
        gui; % the thing guidata returns
        bckg_color;
        DefaultDataDirectory;

        logon;          % OMERO logon        
        client;
        session;
                
        % set by user
        Dst;                
        Src;        
        
        % set by user
        Modulo = 'ModuloAlongT';        % ModuloAlongZ,C,T
        Variable = 'lifetime';          % running variable: lifetime, angle, Yvar, Xvar, wavelength (C), (Z,T,P?) 
        Units = 'ps';                   % angle, rad, pixel        
        Extension = 'sdt';              % source files' extension        
        FLIM_mode = 'TCSPC';            % TCSPC, TCSPC non-imaging, TimeGated, None 
        
        Attr1 = 'Not Set';
        Attr1_ZCT = 'Z';
        Attr1_meaning = 'native';
        Attr1_ZCT_popupmenu_str = {'Z','C','T'};        
        Attr1_meaning_popupmenu_str = {'native','camera','exposure','excitation','polarization'};                        

        Attr2 = 'Not Set';
        Attr2_ZCT = 'Z';
        Attr2_meaning = 'native';
        Attr2_ZCT_popupmenu_str = {'Z','C','T'};        
        Attr2_meaning_popupmenu_str = {'native','camera','exposure','excitation','polarization'};                        
        

        % set by user                
        % Annotations
        image_annotations_file_extension;   % edited string
        data_annotations_file_extension;    % edited string        
        load_dataset_annotations;           % flag
        % set by user ???                
        image_label;    % to be included into xml annotation
                        
        % inferred from data names parsing - WILL BE PUT INTO XML ANNO
        Z;              % [...]
        C;              % [...]
        T;              % [...]
        P;              % [...] Polarization..
        % ONE CAN USE THESE DIMENSIONS IN THE CASE WHEN THERE IS NO MODULO
        % ANNO?? ...    
                             
        % inferred from data names parsing - WILL BE PUT INTO XML ANNO        
        % Volumetric 
        camera;         % 1,2,3
        exposure_time;  % [ 25 35 48 ] 
        exposure_units; % []        
        
        % Spectra & Polarization ?
        
        % SPW ?
        
        %                     
        Modulo_popupmenu_str = {'ModuloAlongZ','ModuloAlongC','ModuloAlongT','none'};
        Variable_popupmenu_str = {'lifetime', 'angle', 'Yvar', 'Xvar', 'wavelength','none'};
        Units_popupmenu_str = {'ps','ns','degree','radian','nm','pixel','none'};
        FLIM_mode_popupmenu_str = {'TCSPC', 'TCSPC non-imaging', 'Time Gated', 'Time Gated non-imaging','none'};        
        Extension_popupmenu_str = {'tif','OME.tiff','sdt','txt','jpg','png','bmp','gif'};         
        
        Annotation_FIle_Extensions = {'irf','txt','pdf','doc','docx','rtf','ppt','pptx','xls','xlsx','csv','m','xml'};
        %
        FOVAnnotationExtensions;
        DatasetAnnotationExtensions;
        
        status = 'not set up';  % status flag
        % 'not set up'
        % 'importing'
        % 'ready'
        
        use_ZCT = false;
               
        LoadMode = [];
        
        SrcList = [];
        
        FOV_names_list; % source - full files or directoreis names ??
                       
    end
    
    methods
%-------------------------------------------------------------------------%      
        function obj = ic_importer_impl()
                                               
            wait = false;
            
            if isdeployed
                wait = true;
            end
    
            profile = profile_controller();
            profile.load_profile();
            
%           obj.Extension = '???';
            obj.bckg_color = [.8 .8 .8]; 
            obj.DefaultDataDirectory = 'C:\';
            
            obj.window = figure( ...
                'Name', 'Imperial College Omero importer', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Position', [0 0 970 120], ...                
                'Toolbar', 'none', ...
                'DockControls', 'off', ...                
                'Resize', 'off', ...                
                'HandleVisibility', 'off', ...
                'Visible','off');

            ic_width = 600;
            %ic_height = ceil(ic_width/1.618);
            ic_height = ceil(ic_width/1.8 );
            set(obj.window,'OuterPosition',[1 1 ic_width ic_height]);
           
            handles = guidata(obj.window);                                                       
            handles.window = obj.window;
                                                           
            handles = obj.setup_layout(handles);   
            handles = obj.setup_menu(handles);
                        
            guidata(obj.window,handles);
            obj.gui = guidata(obj.window);
                        
            if exist([pwd filesep 'ic_importer_settings.xml'],'file') 
                [ settings, ~ ] = xml_read ('ic_importer_settings.xml');    
                %
                obj.logon = settings.logon;
                %
                obj.DefaultDataDirectory = settings.DefaultDataDirectory;        
                obj.Modulo = settings.Modulo;                             
                obj.Variable = settings.Variable;
                obj.Units = settings.Units;        
                obj.FLIM_mode = settings.FLIM_mode;
                obj.Extension = settings.Extension;   
                %
                obj.Attr1_ZCT = settings.Attr1_ZCT;
                obj.Attr1_meaning = settings.Attr1_meaning;
                obj.Attr2_ZCT = settings.Attr2_ZCT;
                obj.Attr2_meaning = settings.Attr2_meaning;                
                %
                obj.set_gui_string_item('Modulo_popupmenu',obj.Modulo);
                obj.set_gui_string_item('Variable_popupmenu',obj.Variable);
                obj.set_gui_string_item('Units_popupmenu',obj.Units);
                obj.set_gui_string_item('FLIM_mode_popupmenu',obj.FLIM_mode);
                obj.set_gui_string_item('Extension_popupmenu',obj.Extension);                            
                
                obj.set_gui_string_item('Attr1_ZCT_popupmenu',obj.Attr1_ZCT);
                obj.set_gui_string_item('Attr2_ZCT_popupmenu',obj.Attr2_ZCT);                
                obj.set_gui_string_item('Attr1_meaning_popupmenu',obj.Attr1_meaning);                                
                obj.set_gui_string_item('Attr2_meaning_popupmenu',obj.Attr2_meaning);                                                
                
                obj.FOVAnnotationExtensions = settings.FOVAnnotationExtensions;
                obj.DatasetAnnotationExtensions = settings.DatasetAnnotationExtensions;
         
                obj.set_space_delimited_string(obj.FOVAnnotationExtensions,obj.gui.FOV_Annot_Extension_template);
                obj.set_space_delimited_string(obj.DatasetAnnotationExtensions,obj.gui.Dataset_Annot_Extension_template);             
            else
                obj.logon = OMERO_logon();
            end
            %
            obj.enable_Attr_ZCT_management;            
            %
            obj.load_omero;                                                
            %
            close all;            
            set(obj.window,'Visible','on');
            set(obj.window,'CloseRequestFcn',@obj.close_request_fcn);                        
            if wait
                waitfor(obj.window);
            end
            %
        end
%-------------------------------------------------------------------------%
        function handles = setup_menu(obj,handles)
            % + File menu
            menu_file = uimenu( obj.window, 'Label', 'File' );
            handles. m1 = uimenu( menu_file, 'Label','Set data directory', 'Callback', @obj.onSetDirectory );        
            handles. m2 = uimenu( menu_file, 'Label','Set list of data directories', 'Callback', @obj.onSetDirectoryList );        
            handles. m3 = uimenu( menu_file,'Label','Set Image','Callback', @obj.onSetImageFile);                      
            handles. m4 = uimenu( menu_file, 'Label', 'Exit', 'Callback', @obj.close_request_fcn );        
            % + Omero menu
            menu_omero = uimenu( obj.window, 'Label', 'OMERO' );
            handles. m5 = uimenu( menu_omero, 'Label', 'Set logon default', 'Callback', @obj.onLogon );        
            handles. m6 = uimenu( menu_omero, 'Label', 'Restore logon', 'Callback', @obj.onRestoreLogon );        
            handles. m7 = uimenu( menu_omero, 'Label','Set Project', 'Callback', @obj.onSetProject,'Separator','on' );
            handles. m8 = uimenu( menu_omero, 'Label','Set Dataset', 'Callback', @obj.onSetDataset );
            handles. m9 = uimenu( menu_omero, 'Label','Set Screen', 'Callback', @obj.onSetScreen );                    
        end
%-------------------------------------------------------------------------%                
        function close_request_fcn(obj,~,~)            
            %
            if strcmp(obj.status,'importing'), obj.onCancel, end; % needed to interrupt possible import..
            %
            obj.save_settings;
            %
            if ~isempty(obj.client)
                disp('Closing OMERO session');                
                obj.client.closeSession();     
            end
            %
            handles = guidata(obj.window);
            %
            % Make sure we clean up all the left over classes
            names = fieldnames(handles);
                      
            for i=1:length(names)
                % Check the field is actually a handle and isn't the window
                % which we need to close right at the end
                if ~strcmp(names{i},'window') && all(ishandle(handles.(names{i})))
                    delete(handles.(names{i}));
                end
            end
            %            
            delete(handles.window);   
            %
            % still not sure.. but something like this
            obj.client = [];
            obj.session = [];
            clear('handles');
            clear('i');
            clear('names');                                        
            clear('obj');
            unloadOmero;
        end        
%-------------------------------------------------------------------------%
        function handles = setup_layout(obj, handles)
            %
            main_layout = uiextras.VBox( 'Parent', obj.window, 'Spacing', 3 );
            top_layout = uiextras.VBox( 'Parent', main_layout, 'Spacing', 3 );            
            lower_layout = uiextras.HBox( 'Parent', main_layout, 'Spacing', 3 );
            set(main_layout,'Sizes',[-3 -1]);
            %    
            display_tabpanel = uiextras.TabPanel( 'Parent', top_layout, 'TabSize', 80 );
            handles.display_tabpanel = display_tabpanel;                                 
            %
            layout1 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', 3 );    
            handles.panel1 = uipanel( 'Parent', layout1 );
            %
            layout2 = uiextras.VBox( 'Parent', display_tabpanel, 'Spacing', 3 );    
            handles.panel2 = uipanel( 'Parent', layout2 );
            %
            set(display_tabpanel, 'TabNames', {'General','Annotations'});
            set(display_tabpanel, 'SelectedChild', 1);        
            %
            % lower..
            lower_left_layout = uiextras.VButtonBox( 'Parent', lower_layout );
            handles.onCheckOut_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Check out','Callback', @obj.onCheckOut );
            handles.onGo_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Go','Callback', @obj.onGo );            
            handles.onCancel_button = uicontrol( 'Parent', lower_left_layout, 'String', 'Cancel','Callback', @obj.onCancel ); 
            lower_right_layout = uiextras.Grid( 'Parent', lower_layout, 'Spacing', 3, 'Padding', 3, 'RowSizes',-1,'ColumnSizes',-1  );                        
            set( lower_left_layout, 'ButtonSize', [100 20], 'Spacing', 5 );   
            set(lower_layout,'Sizes',[-1 -4]);            
            % lower..
            %            
            % "General" panel            
            general_layout = uiextras.Grid( 'Parent', handles.panel1, 'Spacing', 10, 'Padding', 16, 'RowSizes',-1,'ColumnSizes',-1  );
            uicontrol( 'Style', 'text', 'String', 'Modulo ',       'HorizontalAlignment', 'right', 'Parent', general_layout );
            uicontrol( 'Style', 'text', 'String', 'Modulo Variable ', 'HorizontalAlignment', 'right', 'Parent', general_layout );
            uicontrol( 'Style', 'text', 'String', 'Modulo Units ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
            uicontrol( 'Style', 'text', 'String', 'FLIM mode ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
            uicontrol( 'Style', 'text', 'String', 'Extension ',    'HorizontalAlignment', 'right', 'Parent', general_layout );
            %
            handles.Modulo_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Modulo_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onModuloSet ); 
            handles.Variable_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Variable_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onVariableSet );    
            handles.Units_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.Units_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onUnitsSet );    
            handles.FLIM_mode_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.FLIM_mode_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onFLIM_modeSet );    
            handles.Extension_popupmenu = uicontrol( 'Style', 'popupmenu', 'String',obj.Extension_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onExtensionSet );            
            %
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );    
            handles.Attr1_text = uicontrol( 'Style', 'text', 'String', obj.Attr1,'HorizontalAlignment', 'right', 'Parent', general_layout);
            handles.Attr2_text = uicontrol( 'Style', 'text', 'String', obj.Attr2,'HorizontalAlignment', 'right', 'Parent', general_layout);
            %
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );
            handles.Attr1_ZCT_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr1_ZCT_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr1_ZCT  );    
            handles.Attr2_ZCT_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr2_ZCT_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr2_ZCT  );    
            %
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );
            uiextras.Empty( 'Parent', general_layout );
            handles.Attr1_meaning_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr1_meaning_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr1_meaning  );    
            handles.Attr2_meaning_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', obj.Attr2_meaning_popupmenu_str, 'Parent', general_layout,'Callback', @obj.onAttr2_meaning  );    
            %            
            set(general_layout,'RowSizes',[22 22 22 22 22]);
            set(general_layout,'ColumnSizes',[90 170 120 50 100]);
            %
            % lower right
            handles.Src_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','white' );
            handles.Dst_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','white' );
            handles.Indi_name = uicontrol( 'Style', 'text', 'String', '???', 'HorizontalAlignment', 'center', 'Parent', lower_right_layout,'BackgroundColor','red' );
            set(lower_right_layout,'RowSizes',[-1 -1 -1]);
            set(lower_right_layout,'ColumnSizes',-1);
            %
            anno_layout = uiextras.Grid( 'Parent', handles.panel2, 'Spacing', 10, 'Padding', 16, 'RowSizes',-1,'ColumnSizes',-1  );
            uicontrol( 'Style', 'text', 'String', 'FOV extensions',       'HorizontalAlignment', 'right', 'Parent', anno_layout );
            uicontrol( 'Style', 'text', 'String', 'Dataset extensions', 'HorizontalAlignment', 'right', 'Parent', anno_layout );
            %              
            handles.FOV_Annot_Extension_template = uicontrol( 'Style', 'edit', 'Parent', anno_layout,'BackgroundColor','white','Callback',@obj.onSetFOVAnnotationExtensionEdit ); 
            handles.Dataset_Annot_Extension_template = uicontrol( 'Style', 'edit','Parent', anno_layout,'BackgroundColor','white','Callback',@obj.onSetDatasetAnnotationExtensionEdit   );    
            %
            handles.FOV_Annot_Extension_dflt = uicontrol('String', 'All', 'Parent', anno_layout, 'Callback',@obj.onSetFOVAnnotationExtensionsAll ); 
            handles.Dataset_Annot_Extension_dflt = uicontrol('String', 'All', 'Parent', anno_layout, 'Callback',@obj.onSetDatasetAnnotationExtensionsAll ); 
            %
            set(anno_layout,'RowSizes',[22 22 22 22]);
            set(anno_layout,'ColumnSizes',[95 400 45]);            
        end % setup_layout        
%-------------------------------------------------------------------------%        
        function updateInterface(obj,~,~)
            %
            if ~isempty(obj.SrcList)
                set(obj.gui.Src_name,'String','BATCH');
            else
                set(obj.gui.Src_name,'String',obj.Src);
            end
            %            
            if ~isempty(obj.Dst)
                set( obj.gui.Dst_name,'String',char(java.lang.String(obj.Dst.getName().getValue())) );
            end;
            %
            if strcmp(obj.status,'ready')
                set(obj.gui.Indi_name,'BackgroundColor','green')
                if ~isempty(obj.SrcList) % so it should be cleared after each use... 
                    % ????
                    % set(obj.gui.Indi_name,'String',['BATCH ' char(obj.Extension) ' ' char(obj.LoadMode)]);                
                    set(obj.gui.Indi_name,'String','BATCH');                
                else
                    set(obj.gui.Indi_name,'String',[char(obj.Extension) ' ' char(obj.LoadMode)]);                
                end
            else % 'not set up'
                set(obj.gui.Indi_name,'BackgroundColor','red');
                set(obj.gui.Indi_name,'String','????');
                if isempty(obj.Dst) set( obj.gui.Dst_name,'String','????' ), end;
                if isempty(obj.Src) set( obj.gui.Src_name,'String','????' ), end;
            end
            %
        end
%-------------------------------------------------------------------------%        
        function onGo(obj,~,~)
            if ~strcmp(obj.status,'ready'), errordlg('incompatible setups'), return, end;
            obj.status = 'importing';
            obj.EnableEverythingExceptCancel('off');
            
            if ~isempty(obj.SrcList) && isempty(obj.Src) % BATCH
                
               srclist = obj.SrcList; 
               [numdir, numsettings] = size(srclist);
               
               dirs = srclist(:,1);      
                              
               if numsettings > 1
                   modulos =    srclist(:,2);
                   variables =  srclist(:,3);
                   unitss =     srclist(:,4);
                   flim_modes = srclist(:,5);               
                   extensions = srclist(:,6);
               end
                
               hw = waitbar(0, 'transferring data, please wait...');
               for d = 1:numdir                    
                    obj.Src = char(dirs{d});                     
                    % other settings
                    if numsettings > 1
                        obj.Modulo = char(modulos{d});
                        obj.Variable = char(variables{d});
                        obj.Units = char(unitss{d});
                        obj.FLIM_mode = char(flim_modes{d});                                                    
                        obj.Extension = char(extensions{d});
                        %
                        obj.set_gui_string_item('Modulo_popupmenu',obj.Modulo);
                        obj.set_gui_string_item('Variable_popupmenu',obj.Variable);
                        obj.set_gui_string_item('Units_popupmenu',obj.Units);
                        obj.set_gui_string_item('FLIM_mode_popupmenu',obj.FLIM_mode);
                        obj.set_gui_string_item('Extension_popupmenu',obj.Extension);                            
                    end                    
                    %
                    obj.onCheckOut;
                    obj.status = 'importing';
                    %
                    % JOB
                        switch obj.LoadMode,
                            case 'single-Image'
                                try obj.upload_file_as_Omero_Image(obj.Dst,obj.Src), catch err, errordlg(err.message), end;                                    
                            case 'multiple-Image'
                                try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_file_as_Omero_Image), catch err, errordlg(err.message), end;                                                            
                            case 'single-Image single-point'
                                try obj.upload_Image_single_Pix(obj.Dst,obj.Src), catch err, errordlg(err.message), end;
                            case 'multiple-Image single-point'
                                try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_Image_single_Pix), catch err, errordlg(err.message), end;                    
                            case 'single-Image from directory'
                                try obj.upload_dir_as_Omero_Image(obj.Dst,obj.Src), catch err, errordlg(err.message), end;
                            case 'multiple-Image from directory'
                                try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_dir_as_Omero_Image), catch err, errordlg(err.message), end;                    
                            case 'multiple-Image from directory SPW (old)'
                                try obj.upload_Plate, catch err, errordlg(err.message), end;                                        
                            case 'multiple-Image from directory SPW (multi-channel)'
                                try obj.upload_Plate, catch err, errordlg(err.message), end;                                                                                                                        
                        end;                    
                    % JOB                    
                    waitbar(d/numel(dirs), hw);
                    drawnow;                    
               end;                                             
               delete(hw);
               drawnow;
                                                                
            else % no BATCH
                
                switch obj.LoadMode,
                    case 'single-Image'
                        hw = waitbar(0, 'transerring data, please wait...');                                        
                        try obj.upload_file_as_Omero_Image(obj.Dst,obj.Src), catch err, errordlg(err.message), end;                                    
                        delete(hw); drawnow;
                    case 'multiple-Image'
                        try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_file_as_Omero_Image), catch err, errordlg(err.message), end;                                                            
                    case 'single-Image single-point'
                        hw = waitbar(0, 'transerring data, please wait...');                                                                
                        try obj.upload_Image_single_Pix(obj.Dst,obj.Src), catch err, errordlg(err.message), end;
                        delete(hw); drawnow;                        
                    case 'multiple-Image single-point'
                        try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_Image_single_Pix), catch err, errordlg(err.message), end;                    
                    case 'single-Image from directory'
                        try obj.upload_dir_as_Omero_Image(obj.Dst,obj.Src), catch err, errordlg(err.message), end;
                    case 'multiple-Image from directory'
                        try obj.create_new_Dataset_and_load_FOVs_into_it(@obj.upload_dir_as_Omero_Image), catch err, errordlg(err.message), end;                    
                    case 'multiple-Image from directory SPW (old)'
                        try obj.upload_Plate, catch err, errordlg(err.message), end;  
                    case 'multiple-Image from directory SPW (multi-channel)'
                        try obj.upload_Plate, catch err, errordlg(err.message), end;                                                                                        
                end;
                                
            end
                
            obj.EnableEverythingExceptCancel('on');  
            obj.Src = [];
            obj.SrcList = [];
            obj.Dst = [];
            obj.status = 'not set up';            
            obj.updateInterface;
        end        
%-------------------------------------------------------------------------% 
        function onSetFOVAnnotationExtensionsAll(obj,~,~)            
            obj.set_space_delimited_string(obj.Annotation_FIle_Extensions,obj.gui.FOV_Annot_Extension_template)    
            set_Annotation_Extensions(obj,'FOV');
        end
%-------------------------------------------------------------------------%                  
        function onSetDatasetAnnotationExtensionsAll(obj,~,~)               
             obj.set_space_delimited_string(obj.Annotation_FIle_Extensions,obj.gui.Dataset_Annot_Extension_template)
             set_Annotation_Extensions(obj,'Dataset');               
        end                                
%-------------------------------------------------------------------------%                  
        function set_space_delimited_string(obj,src,dst,~) % src - cell array
            whossrc = whos('src');
            if strcmp('char',whossrc.class), src1 = {src}; else src1 = src; end;            
            S = []; 
            for k = 1:numel(src1), S = [S ' ' char(src1{k})]; end;
            S = S(2:numel(S));% to erase first space
            set(dst,'String',S);
        end        
%-------------------------------------------------------------------------%        
        function onCancel(obj,~,~)
            obj.status = 'not set up';
        end
%-------------------------------------------------------------------------% 
        function onCheckOut(obj,~,~)
        % if Dst is Dataset => Src might be or single file (or might be directory), 
        % if Dst is Project or Screen.. Src is definitely a directory        
            obj.status = 'not set up';
            obj.LoadMode = '????';
            %
            if isempty(obj.Dst) || isempty(obj.Src), obj.updateInterface, return, end;
            %
            single_file = false;
            %
            whos_Dst = whos_Object(obj.session,obj.Dst.getId().getValue());
            %
            if strcmp(whos_Dst,'Dataset'), single_file = true; end;
            %
            if single_file
                if exist(obj.Src,'file') && ~isdir(obj.Src) % only files
                    % single file to Omero image - START                    
                    extension = obj.get_valid_file_extension(obj.Src);                    
                    if ~strcmp(obj.Extension,extension), obj.updateInterface, return, end;
                    %
                    if strcmp(obj.Extension,'txt') 
                        obj.LoadMode = 'single-Image single-point';                        
                    elseif strcmp(obj.Extension,'tif') || ... 
                               strcmp(obj.Extension,'OME.tiff') || ... 
                               strcmp(obj.Extension,'sdt') || ...
                               strcmp(obj.Extension,'jpg') || ...                               
                               strcmp(obj.Extension,'png') || ...
                               strcmp(obj.Extension,'bmp') || ...
                               strcmp(obj.Extension,'gif')
                        obj.LoadMode = 'single-Image';                        
                    else % unsuitable extension
                        obj.updateInterface, return; 
                    end;
                    % single file to Omero image - END
                elseif exist(obj.Src,'dir')
                    % directory of files to Omero image
                    % check if there are images with "acting" extension there...
                    files = dir([char(obj.Src) filesep '*.' char(obj.Extension)]);
                    num_files = length(files);
                    if 0 ~= num_files 
                        obj.LoadMode = 'single-Image from directory'; 
                        %
                        % maybe some more settings?
                        %
                    else obj.updateInterface, return, 
                    end;                                        
                    %
                end
            else % many images
                if ~exist(obj.Src,'dir') || ~(strcmp(whos_Dst,'Project') || strcmp(whos_Dst,'Screen')), 
                    obj.updateInterface, return, end;   
                %
                if strcmp(whos_Dst,'Project')                
                    files = dir([char(obj.Src) filesep '*.' char(obj.Extension)]);
                    num_files = length(files);
                    if 0 ~= num_files
                        obj.FOV_names_list = cell(1,num_files);
                        for k = 1:num_files
                            obj.FOV_names_list{k} = [obj.Src filesep char(files(k).name)];
                        end
                        %
                        if strcmp(obj.Extension,'txt')
                            obj.LoadMode = 'multiple-Image single-point';
                        elseif strcmp(obj.Extension,'tif') || ... 
                               strcmp(obj.Extension,'OME.tiff') || ... 
                               strcmp(obj.Extension,'sdt') || ...
                               strcmp(obj.Extension,'jpg') || ...                               
                               strcmp(obj.Extension,'png') || ...
                               strcmp(obj.Extension,'bmp') || ...
                               strcmp(obj.Extension,'gif')
                            obj.LoadMode = 'multiple-Image';      
                        else % unsuitable extension
                            obj.updateInterface, return; 
                        end;                        
                    else % directories case 
                        % TODO ?
                        % check if not Plate Reader's data?
                        % (not sure if that is needed)
                       fov_names_list = []; 
                       contentdir = dir(obj.Src);
                        for k = 1:numel(contentdir)
                            curelem = char(contentdir(k).name);
                            if ~strcmp(curelem,'.') && ~strcmp(curelem,'..') && isdir([char(obj.Src) filesep curelem])
                                % check if there are tifs inside and if
                                % there are, add dir to "fov_names_list"
                                files = dir([char(obj.Src) filesep curelem filesep '*.' char(obj.Extension)]);
                                num_files = length(files);
                                if 0 ~= num_files
                                    %disp(num_files);
                                    fov_names_list = [fov_names_list cellstr([char(obj.Src) filesep curelem])];
                                end
                            end
                        end
                        obj.FOV_names_list = fov_names_list;
                        if ~isempty(obj.FOV_names_list)
                            obj.LoadMode = 'multiple-Image from directory';
                        else % never happens
                            obj.updateInterface, return;
                        end
                    end
                else % Screen
                    if strcmp(char(obj.Extension),'tif') 
                        
                        PlateSetups1 = obj.parse_WP_format(obj.Src); % should always return [] on error
                                                                           
                        if ~isempty(PlateSetups1) % old format - shortcutted for now... 
                            
                           %%%%%%%%% CODE COPY!!!!!
                           fov_names_list = []; 
                           contentdir = dir(obj.Src);
                            for k = 1:numel(contentdir)
                                curelem = char(contentdir(k).name);
                                if ~strcmp(curelem,'.') && ~strcmp(curelem,'..') && isdir([char(obj.Src) filesep curelem])
                                    % check if there are tifs inside and if
                                    % there are, add dir to "fov_names_list"
                                    files = dir([char(obj.Src) filesep curelem filesep '*.' char(obj.Extension)]);
                                    num_files = length(files);
                                    if 0 ~= num_files
                                        %disp(num_files);
                                        fov_names_list = [fov_names_list cellstr([char(obj.Src) filesep curelem])];
                                    end
                                end
                            end
                            obj.FOV_names_list = fov_names_list;
                            if ~isempty(obj.FOV_names_list)
                                obj.LoadMode = 'multiple-Image from directory SPW (old)';
                            else % never happens
                                obj.updateInterface, return;
                            end                                                        
                            %%%%%%%%% CODE COPY!!!!!
                            
                        else % maybe new fromat?
                            
                            PlateSetups2 = obj.parse_MultiChannel_WP_format(obj.Src); % should always return [] on error
                                obj.LoadMode = 'multiple-Image from directory SPW (multi-channel)';
                            if ~isempty(PlateSetups2)
                            else
                                obj.updateInterface, return;
                            end
                            
                        end
                    else % SPW organized not from Imperial plate-reader - no such data examples...
                        obj.updateInterface, return;
                    end
                end                
            end
            %         
            obj.status = 'ready';            
            obj.updateInterface;
            %
        end        
%-------------------------------------------------------------------------%                    
        function onSetDirectory(obj,~,~)
            obj.SrcList = [];
            obj.Src = uigetdir(obj.DefaultDataDirectory,'Select the folder containing the data');     
            %
            if 0 ~= obj.Src            
                obj.DefaultDataDirectory = obj.Src;
                obj.status = 'not set up';
                obj.updateInterface;
            end        
        end 
%-------------------------------------------------------------------------%                                                   
        function onSetDirectoryList(obj,~,~)
            
           [file,path] = uigetfile('*.xlsx;*.xls','Select a text file containing list of data directories',obj.DefaultDataDirectory);            
            
           if file == 0, return, end;

           obj.SrcList = [];
           obj.status = 'not set up';                               
           obj.Src = [];           
           obj.updateInterface;                                   
                      
           try [~,srclist,~] = xlsread([path file]); catch err, errordlg(err.message), return, end;
           
           [numdir, numsettings] = size(srclist);
                dirs = srclist(:,1);
                      
           for d=1:numel(dirs)                    
               if ~isdir(char(dirs{d}))
                   errordlg(['Directory list has not been set: ' char(dirs{d}) ' not a directory']);
                   return;
               end
           end           

           if numsettings > 1
               modulos =    srclist(:,2);
               variables =  srclist(:,3);
               unitss =     srclist(:,4);
               flim_modes = srclist(:,5);               
               extensions = srclist(:,6);
           end
                      
                hw = waitbar(0, 'checking Directory List, please wait...');
                for d = 1:numdir                    
                    obj.Src = char(dirs{d}); 
                    %
                    % other settings
                    if numsettings > 1
                        obj.Modulo = char(modulos{d});
                        obj.Variable = char(variables{d});
                        obj.Units = char(unitss{d});
                        obj.FLIM_mode = char(flim_modes{d});                                                    
                        obj.Extension = char(extensions{d});
                        %
                        obj.set_gui_string_item('Modulo_popupmenu',obj.Modulo);
                        obj.set_gui_string_item('Variable_popupmenu',obj.Variable);
                        obj.set_gui_string_item('Units_popupmenu',obj.Units);
                        obj.set_gui_string_item('FLIM_mode_popupmenu',obj.FLIM_mode);
                        obj.set_gui_string_item('Extension_popupmenu',obj.Extension);                            
                    end                    
                    %
                    obj.onCheckOut;  
                    if strcmp(obj.status,'not set up')
                        errordlg(['Bad settings for data directory: ' char(dirs{d,1}) ' , batch is not set!']);
                        obj.Src = [];
                        delete(hw);
                        drawnow;                        
                        obj.updateInterface;
                        return;
                    end
                    waitbar(d/numel(dirs), hw);
                    drawnow;                    
                end;                                             
                delete(hw);
                drawnow;
                
                obj.DefaultDataDirectory = path;                                                                
                obj.status = 'ready';
                obj.SrcList = srclist;
                obj.Src = [];
                obj.updateInterface;                       
        end
%-------------------------------------------------------------------------%        
        function onLogon(obj,~,~)
            obj.logon = OMERO_logon();
            obj.load_omero;            
        end
%-------------------------------------------------------------------------%        
        function onRestoreLogon(obj,~,~)
            obj.load_omero;
        end
%-------------------------------------------------------------------------%
        function load_omero(obj,~,~)
            try
                obj.client = loadOmero(obj.logon{1});
                obj.session = obj.client.createSession(obj.logon{2},obj.logon{3});
            catch
                obj.client = [];
                obj.session = [];
                errordlg('Error creating OMERO session');           
            end
        end % load_omero
%-------------------------------------------------------------------------%
        function onSetScreen(obj,~,~)    
                obj.SrcList = [];
                scrn = select_Screen(obj.session,[],'Select Screen');
                if ~isempty(scrn)
                    obj.Dst = scrn; 
                    obj.updateInterface;
                else return, 
                end;
                %
%                 if (isempty(obj.Src) || ~isdir(obj.Src)) && isempty(oj.SrcList)
%                     obj.onSetDirectory();
%                 end              
                obj.status = 'not set up';
                obj.updateInterface;                
        end
%-------------------------------------------------------------------------%
        function onSetProject(obj,~,~)                        
                obj.SrcList = [];            
                prj = select_Project(obj.session,[],'Select Project');
                if ~isempty(prj)
                    obj.Dst = prj; 
                else return, 
                end;
                %
%                 if (isempty(obj.Src) || ~isdir(obj.Src)) && isempty(oj.SrcList) 
%                     obj.onSetDirectory();                    
%                 end              
                obj.status = 'not set up';
                obj.updateInterface;                
        end
%-------------------------------------------------------------------------%
        function onSetDataset(obj,~,~)                        
                obj.SrcList = [];            
                dtset = select_Dataset(obj.session,[],'Select Dataset');
                if ~isempty(dtset)
                    obj.Dst = dtset; 
                else return, 
                end;
%                 if isempty(obj.Src) || ~exist(obj.Src,'file') && isempty(oj.SrcList) 
%                     obj.onSetImageFile();
%                 end          
                obj.status = 'not set up';
                obj.updateInterface;
        end
%-------------------------------------------------------------------------%    
        function onSetImageFile(obj,~,~)
                obj.SrcList = [];            
                [filename, pathname] = uigetfile({'*.tif';'*.tiff';'*.sdt';'*.txt'},'Select Image File',obj.DefaultDataDirectory);            
                if isequal(filename,0), return, end;
                %
                obj.Src = [pathname filesep filename];
                obj.DefaultDataDirectory = obj.Src;
                %
                obj.status = 'not set up';
                obj.updateInterface;
        end
%-------------------------------------------------------------------------%  
        function set_gui_string_item(obj,handle,value)             
             s = obj.([(handle) '_str']);
             set(obj.gui.(handle),'Value',find(cellfun(@strcmp,s,repmat({value},1,numel(s)))==1));
        end
%-------------------------------------------------------------------------%  
        function save_settings(obj,~,~)        
            ic_importer_settings = [];
            ic_importer_settings.logon = obj.logon;
            ic_importer_settings.DefaultDataDirectory = obj.DefaultDataDirectory;        
            ic_importer_settings.Modulo = obj.Modulo;                             
            ic_importer_settings.Variable = obj.Variable;
            ic_importer_settings.Units = obj.Units;        
            ic_importer_settings.FLIM_mode = obj.FLIM_mode;
            ic_importer_settings.Extension = obj.Extension;
            
            ic_importer_settings.Attr1 = obj.Attr1;
            ic_importer_settings.Attr1_ZCT = obj.Attr1_ZCT;
            ic_importer_settings.Attr1_meaning = obj.Attr1_meaning;
            ic_importer_settings.Attr2 = obj.Attr2;
            ic_importer_settings.Attr2_ZCT = obj.Attr2_ZCT;
            ic_importer_settings.Attr2_meaning = obj.Attr2_meaning;                
            
            ic_importer_settings.FOVAnnotationExtensions = obj.FOVAnnotationExtensions;
            ic_importer_settings.DatasetAnnotationExtensions = obj.DatasetAnnotationExtensions;
                                    
            xml_write('ic_importer_settings.xml', ic_importer_settings);
        end % save_settings
%-------------------------------------------------------------------------%          
        function onModuloSet(obj,~,~)
              obj.on_popupmenu_set('Modulo');
        end
%-------------------------------------------------------------------------%          
        function onVariableSet(obj,~,~)
              obj.on_popupmenu_set('Variable');
        end
%-------------------------------------------------------------------------%          
        function onUnitsSet(obj,~,~)
              obj.on_popupmenu_set('Units');
        end
%-------------------------------------------------------------------------%          
        function onFLIM_modeSet(obj,~,~)
              obj.on_popupmenu_set('FLIM_mode');
        end
%-------------------------------------------------------------------------%          
        function onExtensionSet(obj,~,~)
              obj.on_popupmenu_set('Extension');
        end        
%-------------------------------------------------------------------------%          
        function onAttr1_ZCT(obj,~,~)
              obj.on_popupmenu_set('Attr1_ZCT');
        end
%-------------------------------------------------------------------------%          
        function onAttr2_ZCT(obj,~,~)
              obj.on_popupmenu_set('Attr2_ZCT');
        end
%-------------------------------------------------------------------------%          
        function onAttr1_meaning(obj,~,~)
              obj.on_popupmenu_set('Attr1_meaning');
        end
%-------------------------------------------------------------------------%          
        function onAttr2_meaning(obj,~,~)
              obj.on_popupmenu_set('Attr2_meaning');
        end
%-------------------------------------------------------------------------%          
        function on_popupmenu_set(obj,pName,~)            
            value = get(obj.gui.([pName '_popupmenu']),'Value');
            obj.(pName) = obj.([pName '_popupmenu_str'])(value);            
        end
%-------------------------------------------------------------------------%                      
        function enable_Attr_ZCT_management(obj,~,~)             
            if obj.use_ZCT, mode = 'on'; else mode = 'off'; end;
            set(obj.gui.Attr1_text,'Enable',mode);
            set(obj.gui.Attr2_text,'Enable',mode);
            set(obj.gui.Attr1_ZCT_popupmenu,'Enable',mode);
            set(obj.gui.Attr2_ZCT_popupmenu,'Enable',mode);
            set(obj.gui.Attr1_meaning_popupmenu,'Enable',mode);
            set(obj.gui.Attr2_meaning_popupmenu,'Enable',mode);                        
        end
%-------------------------------------------------------------------------%                                  
        function onSetFOVAnnotationExtensionEdit(obj,~,~)
            obj.set_Annotation_Extensions('FOV');
        end
%-------------------------------------------------------------------------%                              
        function onSetDatasetAnnotationExtensionEdit(obj,~,~)  
            obj.set_Annotation_Extensions('Dataset');
        end
%-------------------------------------------------------------------------%                              
        function set_Annotation_Extensions(obj,mode,~)
         %         
         switch mode
             case 'FOV'
                 S = get(obj.gui.FOV_Annot_Extension_template,'String');
                 if isempty(S), obj.FOVAnnotationExtensions = []; return, end;
             case 'Dataset'
                 S = get(obj.gui.Dataset_Annot_Extension_template,'String');
                 if isempty(S), obj.DatasetAnnotationExtensions = []; return, end;
         end
            strng = split(' ',S);
            %
            string_OK = true;            
            for k=1:numel(strng)
                token = strng{k};
                token_OK = false;
                for m = 1:numel(obj.Annotation_FIle_Extensions)
                    if strcmp(token,obj.Annotation_FIle_Extensions{m})
                        token_OK = true;
                        break;
                    end
                end
                if ~token_OK, string_OK = false; break, end;
            end

            %
            extensions = [];
            %
            if ~string_OK
                errordlg('bad editing, annotation extensions arent set');
            else
                z = 0;
                for k=1:numel(strng)
                    token = strng{k};
                    for m = 1:numel(obj.Annotation_FIle_Extensions)
                        if strcmp(token,obj.Annotation_FIle_Extensions{m})
                            z = z+1;
                            extensions{z} = token;
                            break;
                        end
                    end
                end
            end;
            %
            switch mode
                case 'FOV'
                    obj.FOVAnnotationExtensions = extensions;
                    if ~string_OK, set(obj.gui.FOV_Annot_Extension_template,'String',[]); end;
                case 'Dataset'
                    obj.DatasetAnnotationExtensions = extensions;            
                     if ~string_OK, set(obj.gui.Dataset_Annot_Extension_template,'String',[]); end;                    
            end            
        end
%-------------------------------------------------------------------------%                                                    
        function EnableEverythingExceptCancel(obj,mode,~)      
                    set(obj.gui.Modulo_popupmenu,'Enable',mode);
                  set(obj.gui.Variable_popupmenu,'Enable',mode);
                     set(obj.gui.Units_popupmenu,'Enable',mode);
                 set(obj.gui.FLIM_mode_popupmenu,'Enable',mode);
                 set(obj.gui.Extension_popupmenu,'Enable',mode);
                          set(obj.gui.Attr1_text,'Enable',mode);
                          set(obj.gui.Attr2_text,'Enable',mode);
                 set(obj.gui.Attr1_ZCT_popupmenu,'Enable',mode);
                 set(obj.gui.Attr2_ZCT_popupmenu,'Enable',mode);
             set(obj.gui.Attr1_meaning_popupmenu,'Enable',mode);
             set(obj.gui.Attr2_meaning_popupmenu,'Enable',mode);
                            set(obj.gui.Src_name,'Enable',mode);
                            set(obj.gui.Dst_name,'Enable',mode);
                           set(obj.gui.Indi_name,'Enable',mode);
        set(obj.gui.FOV_Annot_Extension_template,'Enable',mode);
    set(obj.gui.Dataset_Annot_Extension_template,'Enable',mode);
            set(obj.gui.FOV_Annot_Extension_dflt,'Enable',mode);
        set(obj.gui.Dataset_Annot_Extension_dflt,'Enable',mode);
                                  set(obj.gui.m1,'Enable',mode);
                                  set(obj.gui.m2,'Enable',mode);
                                  set(obj.gui.m3,'Enable',mode);
                                  set(obj.gui.m4,'Enable',mode);
                                  set(obj.gui.m5,'Enable',mode);
                                  set(obj.gui.m6,'Enable',mode);
                                  set(obj.gui.m7,'Enable',mode);
                                  set(obj.gui.m8,'Enable',mode);
                                  set(obj.gui.m9,'Enable',mode);
            set(obj.gui.onCheckOut_button,'Enable',mode);
            set(obj.gui.onGo_button,'Enable',mode); 
            %
            obj.enable_Attr_ZCT_management;
        end
%-------------------------------------------------------------------------%         
        function attach_image_annotations(obj,object,srcname,~)
            %
            ann_extensions = obj.FOVAnnotationExtensions;
            if isempty(ann_extensions) || isempty(object), return, end; 
                        
            % create the list of annotations 
            annotations = [];
            if exist(srcname,'file') && ~isdir(srcname)
                %
                L = length(srcname);
                l = length(char(obj.Extension));
                base = srcname(1:L-l);                
                z = 0;
                for k = 1 : numel(ann_extensions)
                    curext = char(ann_extensions(k));
                    full_ann_name = [base curext];
                    if exist(full_ann_name,'file')
                        z = z + 1;
                        annotations{z} = full_ann_name;
                    end
                end
            elseif isdir(srcname)
                %
                allfilenames = dir([srcname filesep '*.*']);
                annotations = [];
                z = 0;
                for k = 1 : numel(allfilenames)
                    curname = allfilenames(k).name;
                    if ~strcmp('.',curname) && ~strcmp('..',curname)
                        L = length(curname);
                        l = length(char(obj.Extension));
                        if L>l+1 && ~strcmp(obj.Extension,curname(L-l+1:L))
                            z = z + 1;
                            annotations{z} = [srcname filesep curname];
                        end
                    end
                end                
            end
            %
            obj.attach_annotations(object,annotations);
        end
%-------------------------------------------------------------------------%         
        function annotations = get_annotations(obj,folder,mode,~)
            %
            spec = [mode 'AnnotationExtensions'];            
            ann_extensions = obj.(spec);
            %
            annotations = [];
            for k = 1 : numel(ann_extensions)
                curext = char(ann_extensions(k));
                files = dir([folder filesep '*.' curext]);
                for m = 1:numel(files)
                    annotations = [annotations cellstr([folder filesep files(m).name])];
                end
            end
        end                
%-------------------------------------------------------------------------%
       function attach_annotations(obj,object,annotations,~)
            if isempty(annotations), return, end;
            %
            namespace = 'IC_PHOTONICS';
            description = ' ';
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            hw = waitbar(0, 'Attaching annotations...');
            num_files = numel(annotations);
            for k = 1:num_files
                add_Annotation(obj.session, [], ...
                    object, ...
                    sha1, ...
                    file_mime_type, ...
                    char(annotations{k}), ...
                    description, ...
                    namespace);    
                    %
                    waitbar(k/num_files, hw); drawnow;                                                                    
            end                                   
            delete(hw); drawnow;                                                                                                                       
       end       
%-------------------------------------------------------------------------%         
        function imageId = upload_dir_as_Omero_Image(obj,dataset,folder,~)
            %
            session = obj.session;
            modulo = char(obj.Modulo);
            extension = char(obj.Extension);            
            %
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
            %
            file_names = cell(1,num_files);
            for i=1:num_files
                file_names{i} = files(i).name;
            end
            %
            file_names = sort_nat(file_names); % !!
            %
            SizeC = 1;
            SizeZ = 1;
            SizeT = 1;            
            SizeX = [];
            SizeY = [];            
            %
            if strcmp(modulo,'none'), modulo = 'ModuloAlongC'; end; % default
            %
            switch modulo
                case 'ModuloAlongC'
                    SizeC = num_files; % 128 OK, 255 - problems...
                case 'ModuloAlongZ'
                    SizeZ = num_files;
                case 'ModuloAlongT'
                    SizeT = num_files;
                otherwise
                    errordlg('wrong modulo specification'), return;
            end
            %
            queryService = session.getQueryService();
            pixelsService = session.getPixelsService();
            rawPixelsStore = session.createRawPixelsStore(); 
            containerService = session.getContainerService();
            %
            node = com.mathworks.xml.XMLUtils.createDocument('Modulo');
            Modulo = node.getDocumentElement;
            %
            ModuloAlong = node.createElement(modulo);
            ModuloAlong.setAttribute('Type',obj.Variable);
            ModuloAlong.setAttribute('Unit',obj.Units);                              
            %                        
            %transpose_planes = false;
            transpose_planes = true; % :)
            
                  if strcmp(char(obj.Variable),'lifetime') && ~strcmp(char(obj.FLIM_mode),'none') % FLIM!
                      transpose_planes = true;
                      namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';
                      % try to deduce the delays
                      channels_names = cell(1,num_files);
                      for i = 1 : num_files
                          fnamestruct = obj.parse_DIFN_format1(file_names{i});
                          channels_names{i} = fnamestruct.delaystr;
                      end
                      %  
                      delays = zeros(1,numel(channels_names));
                      for f=1:numel(channels_names)
                        delays(f) = str2num(channels_names{f});
                      end                    
                      %
                      if strcmp(char(obj.FLIM_mode),'Time Gated') || strcmp(char(obj.FLIM_mode),'Time Gated non-imaging')
                        ModuloAlong.setAttribute('TypeDescription','Gated');
                           for i=1:length(delays)
                                thisElement = node.createElement('Label'); 
                                thisElement.appendChild(node.createTextNode(num2str(delays(i))));
                                ModuloAlong.appendChild(thisElement);
                           end                        
                      else % ??
                        ModuloAlong.setAttribute('TypeDescription','TCSPC');
                           ModuloAlong.setAttribute('Start',num2str(delays(1))); 
                           step = (delays(end) - delays(1))./(length(delays) -1);
                           ModuloAlong.setAttribute('Step',num2str(step));
                           ModuloAlong.setAttribute('End',num2str(delays(end)));                        
                      end                                                                                                                                                                                    
                  else
                      namespace = 'IC_PHOTONICS';
                      ModuloAlong.setAttribute('TypeDescription','Single_Plane_Image_File_Names');                  
                      %
                      for m = 1:num_files                   
                        thisElement = node.createElement('Label');
                        thisElement.appendChild(node.createTextNode(file_names{m}));
                        ModuloAlong.appendChild(thisElement);
                      end  
                  end
                  %
                  Modulo.setAttribute('namespace',namespace);
                  %
                  Modulo.appendChild(ModuloAlong);
                  
            hw = waitbar(0, 'Loading images...');
            for i = 1 : num_files    
 
            if ~strcmp(obj.status,'importing'), break, end;                
                
            U = imread([folder filesep file_names{i}],extension);
                                                  
                        if isempty(SizeX)
                            [w,h] = size(U);
                            if ~transpose_planes
                                SizeX = w;
                                SizeY = h;                              
                            else 
                                SizeX = h;
                                SizeY = w;                                  
                            end
                            %
                            strings1 = strrep(folder,filesep,'/');
                            str = split('/',strings1);                            
                            imageName = str(length(str));                                                        
                            %
                            img_description = ' ';               
                            %
                            % Lookup the appropriate PixelsType, depending on the type of data
                            pixeltype = get_num_type(U);                                                    
                            p = omero.sys.ParametersI();
                            p.add('type',rstring(pixeltype));       
                            q=['from PixelsType as p where p.value= :type'];
                            pixelsType = queryService.findByQuery(q,p);
                            %
                            iId = pixelsService.createImage(SizeX, SizeY, SizeZ, SizeT, toJavaList([uint32(0:(SizeC - 1))]), pixelsType, imageName, img_description);
                            imageId = iId.getValue();
                            %
                            image = containerService.getImages('Image',  toJavaList(uint64(imageId)),[]).get(0);
                            pixels = image.getPrimaryPixels();
                            pixelsId = pixels.getId().getValue();
                            rawPixelsStore.setPixelsId(pixelsId, true);                             
                        end    
                        %   
                        if ~transpose_planes
                            plane = U;   
                        else
                            plane = U';   
                        end
                        %
                        bytear = ConvertClientToServer(pixels, plane);                        
                        %                        
                        switch modulo
                            case 'ModuloAlongC'
                                rawPixelsStore.setPlane(bytear, int32(0),int32(i-1),int32(0));                
                            case 'ModuloAlongZ'
                                rawPixelsStore.setPlane(bytear, int32(i-1),int32(0),int32(0));        
                            case 'ModuloAlongT'
                                rawPixelsStore.setPlane(bytear, int32(0),int32(0),int32(i-1));        
                        end        
                        %                                                
                        waitbar(i/num_files,hw); drawnow;
            end                    
            delete(hw); drawnow;                 
                  
                  if strcmp(obj.status,'not set up'), obj.updateInterface, return, end;

                  link = omero.model.DatasetImageLinkI;
                  link.setChild(omero.model.ImageI(imageId, false));
                  link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                  session.getUpdateService().saveAndReturnObject(link);                                                                             
                  %                    
                  rawPixelsStore.close();     
                  %  
                  id = java.util.ArrayList();
                  id.add(java.lang.Long(imageId)); %id of the image
                  containerService = session.getContainerService();
                  list = containerService.getImages('Image', id, omero.sys.ParametersI());
                  image = list.get(0);
                  % 
                  add_XmlAnnotation(session,[],image,node);
                                    
                  obj.attach_image_annotations(image,folder);                    
        end                     
%-------------------------------------------------------------------------%       
        function imgId = upload_Image_single_Pix(obj,dataset,full_filename,~)
            %  
            if strcmp(obj.Modulo,'none') || ~strcmp(obj.Extension,'txt')        
                errordlg('Incompatible settings'),
                return,
            end;
            %
            if strcmp(obj.Variable,'lifetime') && ~strcmp(obj.FLIM_mode,'none') && ... 
                    ~strcmp(obj.FLIM_mode,'TCSPC') && ~ strcmp(obj.FLIM_mode,'Time Gated')...
                    && ( strcmp(obj.Units,'ps') || strcmp(obj.Units,'ns') )   
                % this is FLIM..
                if strcmp(obj.FLIM_mode,'TCSPC non-imaging')
                    type_description = 'TCSPC';
                else
                    type_description = 'Gated';
                end
            else % still using Modulo..
                type_description = 'Spectrum';
            end
            %
            try
                D = load(lower(full_filename),'ascii');
            catch err, display(err.message), return, 
            end;
            %
            [~,n_ch1] = size(D);
            chnls = (2:n_ch1)-1;    
            [delays,im_data,~] = load_flim_file(lower(full_filename),chnls);
            %
            pixeltype = get_num_type(im_data);
            %
            str = split(filesep,full_filename);
            fname = char(str(numel(str)));
            if chnls == 1
                imgId = mat2omeroImage(obj.session, im_data, pixeltype, fname,'',[],char(obj.Modulo));
            else
                %
                [sizeT,sizeC] = size(im_data);
                %
                sizeX = 1;
                sizeY = 1;
                sizeZ = 1;
                %
                nativedata = zeros(sizeX,sizeY,sizeZ,sizeC,sizeT);
                %
                for c = 1 : sizeC,
                    nativedata(1,1,1,c,:) = im_data(:,c);
                end
                %
                imgId = mat2omeroImage_native(obj.session, nativedata, pixeltype, fname,'',[]);                                
                %
            end
            %
            link = omero.model.DatasetImageLinkI;
            link.setChild(omero.model.ImageI(imgId, false));
            link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
            obj.session.getUpdateService().saveAndReturnObject(link);
            %    
            node = com.mathworks.xml.XMLUtils.createDocument('Modulo');
            modulo = node.getDocumentElement;     
                namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';    
            modulo.setAttribute('namespace',namespace);        
            ModuloAlong = node.createElement(obj.Modulo);        
            ModuloAlong.setAttribute('Type',obj.Variable);
            ModuloAlong.setAttribute('Unit',obj.Units);            
            ModuloAlong.setAttribute('Start',num2str(delays(1)));
                step = (delays(end) - delays(1))./(length(delays) -1);
            ModuloAlong.setAttribute('Step',num2str(step));
            ModuloAlong.setAttribute('End',num2str(delays(end)));    
            ModuloAlong.setAttribute('TypeDescription',type_description);
            modulo.appendChild(ModuloAlong);
            %
            id = java.util.ArrayList();
            id.add(java.lang.Long(imgId)); %id of the image
            containerService = obj.session.getContainerService();
            list = containerService.getImages('Image', id, omero.sys.ParametersI());
            image = list.get(0);            
            add_XmlAnnotation(obj.session,[],image,node);
            %
            obj.attach_image_annotations(image,full_filename);            
        end        
%-------------------------------------------------------------------------%         
        function extension = get_valid_file_extension(obj,filename,~)
            valid_extensions = obj.Extension_popupmenu_str;
            str = lower(filename);
            L = length(str);            
            extension = [];
            for k = 1:numel(valid_extensions),                                
                    valid_extension = valid_extensions{k};
                    l_ex = length(valid_extension);
                    if strcmp(str(L-l_ex+1:L),lower(valid_extension))
                        extension = valid_extension;
                        break;
                    end;
            end;
        end
%-------------------------------------------------------------------------%         
        function create_new_Dataset_and_load_FOVs_into_it(obj,func,~)
                    new_dataset_name = obj.Src;
                    description = [ 'new dataset created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')]; %?? duplicate
                    new_dataset = create_new_Dataset(obj.session,obj.Dst,new_dataset_name,description);
                    % waitbar
                    hw = waitbar(0, 'Loading files to Omero, please wait');
                    num_dirs = numel(obj.FOV_names_list);
                    for k=1:num_dirs
                        if ~strcmp(obj.status,'importing'), break, end;
                        feval(func,new_dataset,char(obj.FOV_names_list{k}));
                        waitbar(k/num_dirs, hw); drawnow;
                    end
                    delete(hw); drawnow;
                    %
                    if strcmp(obj.status,'importing')
                        obj.attach_annotations(new_dataset,obj.get_annotations(obj.Src,'Dataset'));
                    else
                        % delete new dataset ?
                        obj.updateInterface;                        
                    end                                                                                                        
        end
%-------------------------------------------------------------------------%                 
        function upload_file_as_Omero_Image(obj,dataset,fullfilename)        
                        if obj.is_OME_tif(fullfilename)
                            obj.upload_Image_OME_tif(dataset,fullfilename,' ');  
                        elseif strcmp('sdt',obj.Extension)
                            obj.upload_Image_BH(dataset,fullfilename);
                        else
                            U = imread(fullfilename,char(obj.Extension));
                            %
                            pixeltype = get_num_type(U);
                            %                                             
                            %str = split(filesep,data.Source);
                            strings1 = strrep(fullfilename,filesep,'/');
                            str = split('/',strings1);                            
                            file_name = str(length(str));
                            %
                            % rearrange planes
                            [w,h,Nch] = size(U);
                            ZZ = zeros(Nch,h,w);
                            for c = 1:Nch,
                                ZZ(c,:,:) = squeeze(U(:,:,c))';
                            end;
                            img_description = ' ';
                            imageId = mat2omeroImage(obj.session, ZZ, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                            link = omero.model.DatasetImageLinkI;
                            link.setChild(omero.model.ImageI(imageId, false));
                            link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                            obj.session.getUpdateService().saveAndReturnObject(link); 
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
                            xmlFileName = [tempdir 'metadata.xml'];
                            xml_write(xmlFileName,flimXMLmetadata);
                            %
                            namespace = 'IC_PHOTONICS';
                            description = ' ';
                            %
                            sha1 = char('pending');
                            file_mime_type = char('application/octet-stream');
                            %
                            myimages = getImages(obj.session,imageId); image = myimages(1);
                            %
                            add_Annotation(obj.session, [], ...
                                            image, ...
                                            sha1, ...
                                            file_mime_type, ...
                                            xmlFileName, ...
                                            description, ...
                                            namespace);                                
                            delete(xmlFileName);                                                
                        end 
                        %
                        % TODO ? - ADD ANNOTATIONS - files with the same name, different extensions?
                        %
        end
%-------------------------------------------------------------------------%                 
        function upload_Plate(obj,~,~)
            
            session = obj.session;
            parent = obj.Dst;            
            folder = obj.Src;
            modulo = obj.Modulo;
            
            newdataname = folder;

            if  strcmp(obj.LoadMode,'multiple-Image from directory SPW (old)')            
                try PlateSetups = obj.parse_WP_format(folder); catch err, errordlg(err.message), return, end;
            elseif strcmp(obj.LoadMode,'multiple-Image from directory SPW (multi-channel)') 
                try PlateSetups = obj.parse_MultiChannel_WP_format(folder); catch err, errordlg(err.message), return, end;                                
            end;
                        
            updateService = session.getUpdateService();        
            newdata = omero.model.PlateI();
            newdata.setName(omero.rtypes.rstring(newdataname));    
            newdata.setColumnNamingConvention(omero.rtypes.rstring(PlateSetups.columnNamingConvention));
            newdata.setRowNamingConvention(omero.rtypes.rstring(PlateSetups.rowNamingConvention));            
            newdata = updateService.saveAndReturnObject(newdata);
            link = omero.model.ScreenPlateLinkI;
            link.setChild(newdata);            
            link.setParent(omero.model.ScreenI(parent.getId().getValue(),false));            
            updateService.saveObject(link); 
                
            objId = newdata.getId().getValue();                                
                        
            if strcmp(obj.LoadMode,'multiple-Image from directory SPW (old)')
                %
                for col = 0:PlateSetups.colMaxNum-1,
                for row = 0:PlateSetups.rowMaxNum-1, 
                    
                    if ~strcmp(obj.status,'importing'), break, end;                
                    
                    imgnameslist = [];
                    z = 0;
                    for imgind = 1 : numel(PlateSetups.names)                    
                        if col == PlateSetups.cols(imgind) && row == PlateSetups.rows(imgind)
                            z = z+1;
                            imgnameslist{z} = PlateSetups.names{imgind};                                                                                                                                                                       
                        end;                                        
                    end
                    %
                    if ~isempty(imgnameslist) 
                        %disp(imgnameslist);
                        %disp([col row]);
                        %                    
                            well = omero.model.WellI;    
                            well.setColumn( omero.rtypes.rint(col) );
                            well.setRow( omero.rtypes.rint(row) );
                            well.setPlate( omero.model.PlateI(objId,false) );
                            %ws = omero.model.WellSampleI();

                            for k = 1:numel(imgnameslist)

                                    ws = omero.model.WellSampleI();

                                    strings1 = strrep([folder filesep imgnameslist{k}],filesep,'/');
                                    strings = split('/',strings1);                            
% loading FOV image - starts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    files = dir([folder filesep imgnameslist{k} filesep '*.' PlateSetups.extension]);
                                    num_files = length(files);
                                    if 0==num_files
                                        errordlg('No suitable files in the directory');
                                        return;
                                    end;
                                    %
                                    file_names = cell(1,num_files);
                                    for i=1:num_files
                                        file_names{i} = files(i).name;
                                    end
                                    file_names = sort_nat(file_names);
                                    %
                                    % pixeltype...
                                    U = imread([folder filesep imgnameslist{k} filesep file_names{1}],PlateSetups.extension);                    
                                    pixeltype = get_num_type(U);
                                    %                                                            
                                    Z = [];
                                    %
                                    channels_names = cell(1,num_files);
                                    %
                                    hw = waitbar(0, 'Loading files to Omero, please wait');
                                    for i = 1 : num_files                
                                            U = imread([folder filesep imgnameslist{k} filesep file_names{i}],PlateSetups.extension);                            
                                            % rearrange planes
                                            [w,h,Nch] = size(U);
                                            %
                                            if 1 ~= Nch
                                                errordlg('Single-plane images are expected - can not continue');
                                                return;                                
                                            end;
                                            %
                                            if isempty(Z)
                                                Z = zeros(num_files,h,w);           
                                            end;
                                            %
                                            Z(i,:,:) = squeeze(U(:,:,1))';                            
                                            %
                                            fnamestruct = obj.parse_DIFN_format1(file_names{i});
                                            channels_names{i} = fnamestruct.delaystr; % delay [ps] in string format
                                            %
                                            waitbar(i/num_files, hw);
                                            drawnow;                            
                                    end
                                    delete(hw);
                                    drawnow;                                        
                                    %
                                    new_image_name = char(strings(length(strings)));
                                    new_imageId = mat2omeroImage(session, Z, pixeltype, new_image_name, ' ', channels_names, modulo);                                                            
% loading FOV image - ends %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    ws.setImage( omero.model.ImageI(new_imageId,false) );                            
                                    well.addWellSample(ws);
                                    %
                                    % image file annotations
                                    myimages = getImages(obj.session,new_imageId); image = myimages(1);                                     
                                    obj.attach_annotations(image,obj.get_annotations([folder filesep imgnameslist{k}],'FOV'));
                                    %  
                                    % xml modulo annotation
                                    delaynums = zeros(1,numel(channels_names));
                                    for f=1:numel(channels_names)
                                        delaynums(f) = str2num(channels_names{f});
                                    end
                                    %
                                    xmlnode = create_ModuloAlongDOM(delaynums, [], modulo, 'Gated');
                                    add_XmlAnnotation(session,[],image,xmlnode);
                                    %                                
                            end
                            updateService.saveObject(well);
    %                         %
    %                         ws.setWell( well );        
    %                         well.addWellSample(ws);
    %                         ws = updateService.saveAndReturnObject(ws);                                                                                
                    end % if ~isempty(imagenameslist)                   
                end % for rows
                end % for cols                  
                %
                dataset_annotations = obj.get_annotations(folder,'Dataset');
                obj.attach_annotations(newdata,dataset_annotations);                                
                %
            elseif strcmp(obj.LoadMode,'multiple-Image from directory SPW (multi-channel)')
                %
                for col = 0:PlateSetups.colMaxNum-1,
                for row = 0:PlateSetups.rowMaxNum-1, 
                    %
                    if ~strcmp(obj.status,'importing'), break, end;                
                    %                    
                    imgnameslist = []; % FOVs for the {col,row} well
                    z = 0;
                    for imgind = 1 : numel(PlateSetups.FOV_dirs)                    
                        %
                        if col == PlateSetups.cols(imgind) && row == PlateSetups.rows(imgind)
                            z = z + 1;
                            imgnameslist{z} = PlateSetups.FOV_dirs{imgind};
                        end;                                        
                    end
                    %
                    if ~isempty(imgnameslist) 
                        
                        %disp([col row])
                        %disp(imgnameslist)

                        well = omero.model.WellI;    
                        well.setColumn( omero.rtypes.rint(col) );
                        well.setRow( omero.rtypes.rint(row) );
                        well.setPlate( omero.model.PlateI(objId,false) );
                                                                        
                        for m = 1 : numel(imgnameslist)
                            %                       
                            for K = 1 : numel(PlateSetups.high_dirs)
                                %
                                thisdir = [folder filesep PlateSetups.high_dirs{K} filesep imgnameslist{m}];
                                ws = omero.model.WellSampleI();                                                                
% loading FOV image - starts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    files = dir([thisdir filesep '*.' PlateSetups.extension]);
                                    num_files = length(files);
                                    if 0==num_files
                                        errordlg('No suitable files in the directory');
                                        return;
                                    end;
                                    %
                                    file_names = cell(1,num_files);
                                    for i=1:num_files
                                        file_names{i} = files(i).name;
                                    end
                                    file_names = sort_nat(file_names);
                                    %
                                    % pixeltype...
                                    U = imread([thisdir filesep file_names{1}],PlateSetups.extension);                    
                                    pixeltype = get_num_type(U);
                                    %                                                            
                                    Z = [];
                                    %
                                    fnamestruct = obj.parse_DIFN_format1(file_names{i});
                                    if ~isempty(fnamestruct)                                    
                                        channels_names = cell(1,num_files);
                                    else
                                        channels_names = [];
                                    end
                                    %
                                    hw = waitbar(0, 'Loading files to Omero, please wait');
                                    for i = 1 : num_files                
                                            U = imread([thisdir filesep file_names{i}],PlateSetups.extension);                            
                                            % rearrange planes
                                            [w,h,Nch] = size(U);
                                            %
                                            if 1 ~= Nch
                                                errordlg('Single-plane images are expected - can not continue');
                                                return;                                
                                            end;
                                            %
                                            if isempty(Z)
                                                Z = zeros(num_files,h,w);           
                                            end;
                                            %
                                            Z(i,:,:) = squeeze(U(:,:,1))';                            
                                            %
                                            fnamestruct = obj.parse_DIFN_format1(file_names{i});
                                            if ~isempty(fnamestruct)
                                                channels_names{i} = fnamestruct.delaystr; % delay [ps] in string format
                                            end
                                            %
                                            waitbar(i/num_files, hw);
                                            drawnow;                            
                                    end
                                    delete(hw);
                                    drawnow;                                        
                                    %
                                    new_image_name = ['MODALITY = ' PlateSetups.high_dirs{K} ' FOVNAME = ' imgnameslist{m}];
                                    new_imageId = mat2omeroImage(session, Z, pixeltype, new_image_name, ' ', channels_names, modulo);
                                    %
% loading FOV image - ends %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    ws.setImage( omero.model.ImageI(new_imageId,false) );                            
                                    well.addWellSample(ws);
                                    %
                                    % IMAGE ANNOTATIONS
                                    myimages = getImages(obj.session,new_imageId); image = myimages(1);
                                    FOV_annotations = obj.get_annotations(thisdir,'FOV');
                                    obj.attach_annotations(image,FOV_annotations);
                                    %
                                    % XML IMAGE ANNOTATIONS                                    
                                    % add xml modulo annotation
                                    if ~isempty(channels_names)
                                        delaynums = zeros(1,numel(channels_names));
                                        for f=1:numel(channels_names)
                                            delaynums(f) = str2num(channels_names{f});
                                        end
                                        %
                                        xmlnode = create_ModuloAlongDOM(delaynums, [], modulo, 'Gated');
                                        add_XmlAnnotation(session,[],image,xmlnode);
                                    end
                            end % for K = 1 : numel(PlateSetups.high_dirs)                             
                            %
                        end % for i = 1 : numel(imgnameslist)
                        %
                        updateService.saveObject(well);                        
                        %
                    end %if ~isempty(imgnameslist) 
                    
                end % for col = 0:PlateSetups.colMaxNum-1,
                end % for row = 0:PlateSetups.rowMaxNum-1,                                 
                %
                % (TWO-LEVEL) DATA ANNOTATIONS
                obj.attach_annotations(newdata,obj.get_annotations(folder,'Dataset'));
                %
                for K = 1 : numel(PlateSetups.high_dirs)
                    obj.attach_annotations(newdata,obj.get_annotations([folder filesep PlateSetups.high_dirs{K}],'Dataset'));                    
                end
                %
            end %if strcmp(obj.LoadMode,'multiple-Image from directory SPW (old)')            
            %
        end
%-------------------------------------------------------------------------%                 
        function PlateSetups = parse_MultiChannel_WP_format(obj,folder,~,~)
            
            PlateSetups = [];
            %            
            try
                high_dirs = []; 
                z = 0;
                contentdir = dir(obj.Src);
                            for k = 1:numel(contentdir)
                                curelem = char(contentdir(k).name);
                                if ~strcmp(curelem,'.') && ~strcmp(curelem,'..') && isdir([char(obj.Src) filesep curelem])
                                    z = z + 1;
                                    high_dirs{z} = curelem;
                                end
                            end                                
                % ENSURE THAT EVERY HIGH-DIR (MODALITY) CONTAINS LIST OF DIRS (FOVS) WITH THE SAME NAMES
                % FIRST HIGH LEVEL DIRECTORY
                firstdirs = dir([folder filesep char(high_dirs(1))]);
                            z=0;
                            fovdirnames = [];
                            for k = 1:numel(firstdirs)
                                curelem = char(firstdirs(k).name);
                                if ~strcmp(curelem,'.') && ~strcmp(curelem,'..') && isdir([char(obj.Src) filesep char(high_dirs(1)) filesep curelem])
                                    z = z + 1;
                                    fovdirnames{z} = curelem;
                                end
                            end                        
                %
                fovmetadata = extract_metadata(fovdirnames);
                %
                N_high_dirs = numel(high_dirs);            
                for K = 1 : N_high_dirs
                        curhighdirs = dir([folder filesep char(high_dirs(K))]);
                            z=0;
                            curfovdirnames = [];
                            for k = 1:numel(curhighdirs)
                                curelem = char(curhighdirs(k).name);
                                if ~strcmp(curelem,'.') && ~strcmp(curelem,'..') && isdir([char(obj.Src) filesep char(high_dirs(1)) filesep curelem])
                                    z = z + 1;
                                    curfovdirnames{z} = curelem;
                                end
                            end                        
                    %
                    curfovmetadata = extract_metadata(curfovdirnames);
                    if numel(curfovmetadata.Well_FOV) ~= numel(fovmetadata.Well_FOV), errordlg('inconsistent FOV names'), return, end; 
                    for m=1:numel(fovmetadata.Well_FOV)
                        if ~strcmp(char(curfovmetadata.Well_FOV(m)),char(fovmetadata.Well_FOV(m))), errordlg('inconsistent FOV names'), return, end; 
                    end;                                
                end

                PlateSetups.high_dirs = high_dirs;
                PlateSetups.FOV_dirs = fovdirnames;
                PlateSetups.FOV_metadata = fovmetadata;            
                %
                PlateSetups.colMaxNum = 12;
                PlateSetups.rowMaxNum = 8;
                PlateSetups.letters = 'ABCDEFGH';
                PlateSetups.columnNamingConvention = 'number'; % 'Column_Names';
                PlateSetups.rowNamingConvention = 'letter'; %'Row_Names'; 
                PlateSetups.extension = 'tif';
                
                % use fovmetadata to define ros, cols
                PlateSetups.cols = zeros(1,numel(fovdirnames));
                PlateSetups.rows = zeros(1,numel(fovdirnames));
                for k = 1:numel(fovdirnames)
                    PlateSetups.cols(1,k) = fovmetadata.Column{k} - 1;
                    fovlet = char(fovmetadata.Row{k});
                    PlateSetups.rows(1,k) = find(PlateSetups.letters == fovlet) - 1;
                end
                    
            catch err
             display(err.message);    
            end                                                              
        end
%-------------------------------------------------------------------------%
        function ret = parse_WP_format(obj,folder,~)

            % A-7 - FOV00239

            ret = [];

            try
                letters = 'ABCDEFGH';

                dirlist = [];
                totlist = dir(folder);

                    z = 0;
                    for k=3:length(totlist)
                        if 1==totlist(k).isdir
                            z=z+1;
                            dirlist{z} = totlist(k).name;
                        end;
                    end  

                dirlist = sort_nat(dirlist);
                num_dirs = numel(dirlist);

                rows = zeros(1,num_dirs);
                cols = zeros(1,num_dirs);
                params = zeros(1,num_dirs);
                names = cell(1,num_dirs);

                for i = 1 : num_dirs        
                    iName = dirlist{i};        
                    names{i} = iName;                
                    str = split('-',iName);
                    imlet = char(str(1));
                    rows(1,i) = find(letters==imlet)-1;
                    cols(1,i) = str2num(char(str(2)))-1;        
                    %
                    str = split(' _ FOV',iName);
                    params(1,i) = str2num(char(str(length(str))));
                end        

                ret.names = names;
                ret.rows = rows;
                ret.cols = cols;
                ret.params  = params;
                ret.colMaxNum = 12;
                ret.rowMaxNum = 8;
                ret.extension = 'tif';
                ret.columnNamingConvention = 'number';  % 'Column_Names';
                ret.rowNamingConvention = 'letter';     % 'Row_Names'; 

            catch err
                display(err.message);    
            end
        end 
%-------------------------------------------------------------------------%
        function imageId = upload_Image_OME_tif(obj,dataset,filename,description,~) 

            factory = obj.session;
            
            ometiffdata = OME_tif2Omero_Image(factory,filename,description);

            imageId = ometiffdata.imageId;
            s = ometiffdata.s;

            if isempty(imageId) || isempty(dataset), errordlg('bad input'); return; end;                   

            detached_metadata_xml_filename = [tempdir 'metadata.xml'];
            fid = fopen(detached_metadata_xml_filename,'w');    
                fwrite(fid,s,'*uint8');
            fclose(fid);

            link = omero.model.DatasetImageLinkI;
            link.setChild(omero.model.ImageI(imageId, false));
            link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
            factory.getUpdateService().saveAndReturnObject(link);

            myimages = getImages(factory,imageId.getValue()); image = myimages(1);        

            namespace = 'IC_PHOTONICS';
            description = ' ';
            %
            sha1 = char('pending');
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(factory, [], ...
                            image, ...
                            sha1, ...
                            file_mime_type, ...
                            detached_metadata_xml_filename, ...
                            description, ...
                            namespace);    
            %
            delete(detached_metadata_xml_filename);  

            % use "s" to create XML annotation
            [parseResult,~] = xmlreadstring(s);
            tree = xml_read(parseResult);

                    modlo = [];
                    modulo = [];
                    FLIM_type = [];
                    Delays = [];

                    if isfield(tree,'ModuloAlongC')
                        modlo = tree.ModuloAlongC;
                        modulo = 'ModuloAlongC';
                    elseif isfield(tree,'ModuloAlongT')
                        modlo = tree.ModuloAlongT;
                        modulo = 'ModuloAlongT';
                    elseif  isfield(tree,'ModuloAlongZ')
                        modlo = tree.ModuloAlongZ;
                        modulo = 'ModuloAlongZ';
                    end   
                    %
                    if ~isempty(modlo)
                        if isfield(modlo.ATTRIBUTE,'Start')
                            start = modlo.ATTRIBUTE.Start;
                            step = modlo.ATTRIBUTE.Step;
                            e = modlo.ATTRIBUTE.End;                
                            Delays = start:step:e;
                        elseif isfield(modlo.Label)
                            str_delays = modlo.Label;
                            Delays = cell2mat(str_delays);
                        end
                        %    
                        if isfield(modlo.ATTRIBUTE,'Description')
                            FLIM_type = modlo.ATTRIBUTE.Description;
                        end
                    end

                    if isfield(tree,'SA_COLON_StructuredAnnotations') % supposed to be here...

                        if  isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongT') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Type)

                            modulo = 'ModuloAlongT';
                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Start')
                                start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Start;
                                step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Step;
                                e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.End;                
                                Delays = start:step:e;
                            else
                                str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.Label;
                                Delays = cell2mat(str_delays);
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Unit')
                                if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Unit,'ns')
                                    Delays = Delays*1000; % assumes units are ps  unless specified as ns
                                end
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Description')
                                FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Description;
                            end                    

                        elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongC') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Type)

                            modulo = 'ModuloAlongC';
                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Start')
                                start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Start;
                                step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Step;
                                e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.End;                
                                Delays = start:step:e;
                            else
                                str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.Label;
                                Delays = cell2mat(str_delays);
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Unit')
                                if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit,'ns')
                                    Delays = Delays*1000; % assumes units are ps  unless specified as ns
                                end
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Description')
                                FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Description;
                            end                    

                        elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongZ') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Type)     

                            modulo = 'ModuloAlongZ';
                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Start')
                                start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Start;
                                step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Step;
                                e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.End;                
                                Delays = start:step:e;
                            else
                                str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.Label;
                                Delays = cell2mat(str_delays);
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Unit')
                                if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Unit,'ns')
                                    Delays = Delays*1000; % assumes units are ps  unless specified as ns
                                end
                            end

                            if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Description')
                                FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Description;
                            end                    

                        end

                        if isempty(FLIM_type)
                            if isfield(tree.Image,'HRI'), FLIM_type = 'Gated'; end;
                            if isfield(tree.Image,'FLIMType'), FLIM_type = tree.Image.FLIMType; end;
                        end

                        if isempty(FLIM_type) FLIM_type = 'TCSPC'; end; % aaaaaa!!!

                    end        

            % last chance that it is LaVision modulo Z format..
            if isempty(Delays) && isempty(modulo) && isempty(FLIM_type)    
                pixelsList = image.copyPixels();    
                pixels = pixelsList.get(0);                        
                SizeC = pixels.getSizeC().getValue();
                SizeZ = pixels.getSizeZ().getValue();
                SizeT = pixels.getSizeT().getValue();
                %
                if 1 == SizeC && 1 == SizeT && SizeZ > 1
                    if isfield(tree.Image.Pixels.ATTRIBUTE,'PhysicalSizeZ')
                        physSizeZ = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ*1000;     % assume this is in ns so convert to ps
                        Delays = (0:SizeZ-1)*physSizeZ;
                        modulo = 'ModuloAlongZ';
                        FLIM_type = 'TCSPC';
                    end
                end                        
            end
            %
            if ~isempty(Delays) && ~isempty(modulo) && ~isempty(FLIM_type)
                xmlnode = create_ModuloAlongDOM(Delays, [], modulo, FLIM_type);
                add_XmlAnnotation(factory,[],image,xmlnode);
                %
                add_Original_Metadata_Annotation(factory,[],image,filename);
                %
            end           
            %             
        end
%-------------------------------------------------------------------------%
        function res = is_OME_tif(obj,filename,~)

            res = false;

            if isempty(filename)
                errordlg('bad input');
                return;
            end;                   

            s = [];
            try    
                tT = Tiff(filename);
                s = tT.getTag('ImageDescription');
            catch
                return;
            end
            if isempty(s), return; end;    
        
             [parseResult,~] = xmlreadstring(s);
             tree = xml_read(parseResult);

            try
                if isfield(tree.Image.Pixels.ATTRIBUTE,'SizeZ'), res = true; end;
            catch err
                disp(err.message);
                return;
            end

        end
%-------------------------------------------------------------------------%
        function ret = parse_DIFN_format1(obj, DelayedImageFileName, ~)

        ret = [];

            try

                str = split(' ',DelayedImageFileName);                            

                if 1 == numel(str)

                    str1 = split('_',DelayedImageFileName);                            
                    str2 = char(str1(2));
                    str3 = split('.',str2);
                        ret.delaystr = num2str(str2num(char(str3(1))));    

                elseif 2 == numel(str)

                     str = split(' ',DelayedImageFileName);                            
                     str1 = char(str(2));     
                     str2 = split('_',str1);                            
                     str3 = char(str2(2));
                     str4 = split('.',str3);
                        ret.delaystr = num2str(str2num(char(str4(1))));
                     str5 = split('_',char(str(1)));
                        ret.integrationtimestr = num2str(str2num(char(str5(2))));                
                end

            catch err
                disp(err.message);
            end
        end
%-------------------------------------------------------------------------%
        function upload_Image_BH(obj, dataset, full_filename, ~)
            
            modulo = obj.Modulo;

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
                imgId = mat2omeroImage_native(obj.session, data, pixeltype, filename,  img_description, []);
                %
                link = omero.model.DatasetImageLinkI;
                    link.setChild(omero.model.ImageI(imgId, false));
                        link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
                            obj.session.getUpdateService().saveAndReturnObject(link);     
                %
                myimages = getImages(obj.session,imgId); image = myimages(1);        
                %        
                xmlnode = create_ModuloAlongDOM(Delays, [], modulo, 'TCSPC');
                add_XmlAnnotation(obj.session,[],image,xmlnode);
                %
                add_Original_Metadata_Annotation(obj.session,[],image,full_filename);
                %
        end
%-------------------------------------------------------------------------%
    end % methods
    %    
end
