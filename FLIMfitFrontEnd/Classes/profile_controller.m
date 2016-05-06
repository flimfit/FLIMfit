classdef profile_controller

    properties
       
        profile_file
        
    end
    
    methods(Static)
       
        function profile_def = profile_definitions()

            % Data Preferences
            profile_def.Data.Automatically_Estimate_IRF_Background = true;
            profile_def.Data.Default_Camera_Background = 0;
            profile_def.Data.Default_Rep_Rate = 80;

            % Fitting Preferences
            profile_def.Fitting.Maximum_Iterations = 100;
            profile_def.Fitting.Confidence_Interval = 0.05;

            % Display Preferences
            profile_def.Display.Invert_Colourscale = false;
            profile_def.Display.Gamma_Factor = 0.6;
            profile_def.Display.Text_Size = 12;
            
            % Tools Preferences
            profile_def.Tools.IRF_Shift_Map_Max_Shift = 200;
            profile_def.Tools.IRF_Shift_Map_Max_Downsampling = 4;
            
            % Export Preferences
            profile_def.Export.Plotter_Width_Px = 400;
        end

        
    end
        
    
    methods
        
        function obj = profile_controller()
            folder = getapplicationdatadir('FLIMfit',true,true);
            subfolder = [folder filesep 'Profiles']; 
            if ~exist(subfolder,'dir')
                mkdir(subfolder)
            end
            obj.profile_file = [ subfolder filesep 'FLIMfitPrefs.mat' ];
        end
        
        function current_prof = get_profile(obj)
            
            global prof;
            
            if isempty(prof)
                obj.load_profile();
            end
            
            current_prof = prof;
        end
            
            
 
        function load_profile(obj)
        
            global prof;

            
            if exist(obj.profile_file,'file')
                
                % If profile exists, load it from file
                load(obj.profile_file);
            else
                
                % If no existing profile, create it from definitions
                % Need to replace all options with default
                
                profile_def = obj.profile_definitions();

                groups = fieldnames(profile_def);
                for i=1:length(groups)

                    group = profile_def.(groups{i});
                    params = fieldnames(group);

                    for j=1:length(params)
                        param = group.(params{j});
                        if iscell(param) && ~isempty(param)
                            group.(params{j}) = param{1};
                        end 
                    end
                    
                    prof.(groups{i}) = group;

                end

            end
            
        end
        
        function set_profile(obj)
            
            global prof;

            % Setup Figures

            f = figure(56);

            set(f,'Name','FLIMfit Preferences',...
                  'NumberTitle', 'off', ...
                  'Toolbar','none',...
                  'MenuBar','none');

            clf(f);
            layout = uiextras.VBox( 'Parent', f );

            tab_panel = uiextras.TabPanel( 'Parent', layout );
            button_layout = uiextras.HBox( 'Parent', layout );

            uicontrol( 'Style', 'pushbutton', ... 
                       'String', 'Cancel', ...
                       'Callback', @cancel_callback, ...
                       'Parent', button_layout );

            uicontrol( 'Style', 'pushbutton', ... 
                       'String', 'OK', ...
                       'Callback', @ok_callback, ...
                       'Parent', button_layout );   

            layout.Sizes = [-1 22];

            % Get preference definitions
            profile_def = obj.profile_definitions();
            groups = fieldnames(profile_def);

            com.mathworks.mwswing.MJUtilities.initJIDE();
            
            % Setup tab panels
            for i=1:length(groups)
                h(i) = uipanel( 'Parent', tab_panel );

                if isfield( prof, groups{i} )
                    cur_profile = prof.(groups{i});
                else
                    cur_profile = struct();
                end

                propertiesGUI(h(i),profile_def.(groups{i}),cur_profile,i);
            end

            tab_panel.TabNames = groups;
            tab_panel.SelectedChild = 1;


            function cancel_callback(~,~,~)
                close(f);
            end

            function ok_callback(~,~,~)

                for j=1:length(groups)
                    prof.(groups{j}) = getappdata(h(j),'mirror');
                end
                
                save(obj.profile_file,'prof');

                close(f);
            end
        end
    end  
end
    