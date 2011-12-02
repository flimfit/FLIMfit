function batch_fit(root_path,mode,data_settings_file,fit_params)
    
   handles = struct;
   
   % Set up data and fit controllers
   %------------------------------------
   data_series_controller = flim_data_series_controller(); 
   
   handles.fit_params = fit_params;
   handles.data_series_controller = data_series_controller;
   
   fit_controller = flim_fit_controller(handles);
   lh = addlistener(fit_controller,'fit_completed',@start_next_run); %#ok
   
   
   % Set up result files
   %------------------------------------
   path_parts = split(filesep,root_path);
   
   batch_folder = [root_path filesep '..' filesep 'Batch fit - ' path_parts{end} ' - ' datestr(now,'yyyy-mm-dd HH-MM-SS') filesep];
   mkdir(batch_folder);
   mkdir([batch_folder 'images\']);
   
   fit_result_file = [batch_folder 'FitResults.hdf5'];
   fit_summary_file = [batch_folder 'FitSummary.csv'];
   raw_folder = [batch_folder 'images\'];
   plot_file = [batch_folder 'FitPlot.tiff'];
   
   fit_param_file = [batch_folder 'FitParameters.xml'];
   export_data_setting_file = [batch_folder 'DataSettings.xml'];
   
   % Save setting files
   %----------------------------------------------
   copyfile(data_settings_file,export_data_setting_file);
   fit_params.save_fitting_params(fit_param_file);
  

   % Check how many files we have in the fit
   %----------------------------------------------
   if strcmp(mode,'TCSPC')

        files = [dir([root_path '*.sdt']) dir([root_path '*.txt'])];
        num_datasets = length(files);

        channel = request_channel();

    else % widefield
        contents = dir(root_path);

        % Get children of root path which are directories
        folders = [];
        for j=1:length(contents)
            if contents(j).isdir && contents(j).name(1) ~= '.'
                folders = [folders contents(j)];
            end
        end

        num_datasets = length(folders); 

   end    

   % Determine number of runs required
   %------------------------------------------
   n_thread = fit_params.n_thread;
   n_run = ceil(num_datasets / n_thread);
   cur_run = 1;
   
   global g_fit_plot_controller
   if ~isempty(g_fit_plot_controller)
        old_fit_controller = g_fit_plot_controller.fit_controller;
        g_fit_plot_controller.fit_controller = fit_controller;
   end
   
   start_next_run([],[]);
   

   function start_next_run(~,~) 
       
       
       % Save Results of last fit
       %-------------------------------
       if cur_run > 1
            fit_controller.save_fit_result(fit_result_file);
            fit_controller.save_param_table(fit_summary_file,true,true);
            fit_controller.save_raw_images(raw_folder);
            %if ~isempty(g_fit_plot_controller)
            %    g_fit_plot_controller.export_plots(plot_file)
            %end
       end
       
       if cur_run > n_run
           
           if ~isempty(g_fit_plot_controller)
                g_fit_plot_controller.fit_controller = old_fit_controller;
           end

           clearvars fit_controller data_series_controller handles;
           
           msgbox('Batch Fit Completed','Global Processing','help');
           
       else
       
           % Determine datasets to process
           first = (cur_run-1) * n_thread + 1;
           last = first + n_thread - 1;
           last = min(last,num_datasets);
           selected = first:last;

           cur_run = cur_run + 1;

           
           data_series_controller.load_data_series(root_path,mode,data_settings_file,selected);

           fit_controller.fit();


       end
   end
       
end