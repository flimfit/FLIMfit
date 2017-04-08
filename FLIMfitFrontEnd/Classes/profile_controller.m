classdef profile_controller < handle

    % Make singleton

    methods (Static)
        function single_obj = get_instance
            persistent local_obj
            if isempty(local_obj) || ~isvalid(local_obj)
                local_obj = profile_controller;
            end
            single_obj = local_obj;
        end
    end

    
    methods (Access = private)
        function obj = profile_controller
            folder = getapplicationdatadir('FLIMfit',true,true);
            subfolder = [folder filesep 'Profiles']; 
            if ~exist(subfolder,'dir')
                mkdir(subfolder)
            end
            obj.profile_file = [ subfolder filesep 'FLIMfitPrefs.mat' ];
        end
    end
        
    properties (Access = private)
        profile_file;
        profile;
    end
        
    methods(Static)
       
        function profile_def = profile_definitions()

            % Data Preferences
            profile_def.Data.Automatically_Estimate_IRF_Background = true;
            profile_def.Data.Default_Camera_Background = 0;
            profile_def.Data.Default_Rep_Rate = 80;
            profile_def.Data.Default_Gate_Max = 1e8;
            
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
                
        function prof = get_profile(obj)
            if isempty(obj.profile)
                obj.load_profile();
            end
            prof = obj.profile;
        end
 
        function load_profile(obj)
        
            prof = struct();
            
            try
                if exist(obj.profile_file,'file')
                    % If profile exists, load it from file
                    prof = load(obj.profile_file);
                    prof = prof.prof;
                end
            catch e
                disp('Error loading saved preferences, reverting to defaults');
            end
            
            % Make sure we've got everything defined
                
            new_prof = obj.profile_definitions();

            groups = fieldnames(prof);
            for i=1:length(groups)

                group = prof.(groups{i});
                params = fieldnames(group);

                for j=1:length(params)
                    param = group.(params{j});
                    if iscell(param) && ~isempty(param)
                        group.(params{j}) = param{1};
                    end 
                end

                new_prof.(groups{i}) = group;

            end

            obj.profile = new_prof;
            
        end
        
        function set_profile(obj)
                        
            com.mathworks.mwswing.MJUtilities.initJIDE();
            
            [~,obj.profile] = propertiesGUI(obj.profile);
            
            prof = obj.profile;
            save(obj.profile_file,'prof');

        end
    end  
end
    