classdef flim_project_controller < flim_data_series_observer
   
    properties
        fit_controller;
        result_controller;
        model_controller;
        fitting_params_controller;
    end
    
    methods
    
        function obj = flim_project_controller(handles)
            obj = obj@flim_data_series_observer(handles.data_series_controller);
            assign_handles(obj,handles);
        end
        
        function save(obj,root,folder)
            
            root = ensure_trailing_slash(root);
            folder = [root folder];
            folder = ensure_trailing_slash(folder);            

            if exist(folder,'dir')
                r = warndlg('Replace existing project?','Project folder already exists',{'Cancel','Replace'});
                if strcmp(r,'Replace')
                    rmdir(folder,'s');
                else
                    return
                end
            end
            
            mkdir(folder);
            
            d = obj.data_series;
            
            d.save_data_settings([folder 'data_settings.xml']);

            % move this into data_series_controller
            data_info.file_names = d.file_names;
            data_info.file_names = strrep(data_info.file_names,root,'');
            data_info.reader_settings = d.reader_settings;
            data_info.ZCT = d.ZCT;
            data_info.channels = d.channels;
            data_info.polarisation_resolved = d.polarisation_resolved;
            
            serialise_object(data_info,[folder 'data.xml'],'data_info');
            
            if ~isempty(d.seg_mask)
                mkdir([folder 'segmentation']);
                for i=1:d.n_datasets
                    file = [folder 'segmentation' filesep d.names{i} ' segmentation.tif'];
                    SaveUInt16Tiff(d.seg_mask(:,:,i),file);
                end
            end
            
            if exist(d.multid_filters_file,'file')
                copyfile(d.multid_filters_file,[folder 'multid_segmentation.xml']);
            end
            
            obj.fitting_params_controller.save([folder 'fit_settings.xml']);
            obj.model_controller.save([folder 'fit_model.xml']);
            
            if (~isempty(obj.result_controller.fit_result))
                obj.result_controller.fit_result.save([folder 'fit_results.hdf5']);
                obj.result_controller.save_param_table([folder 'fit_results.xlsx']);
            end
        end
        
        function load(obj,folder)

            if folder(end)==filesep
                folder = folder(1:end-1); 
            end
            
            root = ensure_trailing_slash(fileparts(folder));
            folder = ensure_trailing_slash(folder);
            
            doc_node = xmlread([folder 'data.xml']);
            data_info = marshal_object(doc_node,'data_info',struct());
            data_info.file_names = cellfun(@(x) [root x],data_info.file_names,'UniformOutput',false);
             
            obj.data_series_controller.clear();
            
            % TODO: move this into data_series_controller
            d = obj.data_series_controller.data_series;
            d.n_datasets = length(data_info.file_names);
            d.multid_filters_file = [folder 'multid_segmentation.xml'];
            d.header_text = folder;
            
            d.load_multiple(data_info.file_names, ...
                            'polarisation_resolved', data_info.polarisation_resolved, ...
                            'data_settings_files', [folder 'data_settings.xml'], ...
                            'ZCT', data_info.ZCT, ...
                            'channels', data_info.channels, ...
                            'reader_settings', data_info.reader_settings);
            
            if isfolder([folder 'segmentation'])
                d.seg_mask = uint16.empty();
                for i=1:d.n_datasets
                    file = [folder 'segmentation' filesep d.names{i} ' segmentation.tif'];
                    if exist(file,'file')   
                        d.seg_mask(:,:,i) = imread(file);
                    end
                end
            end

            obj.data_series_controller.loaded_new_dataset();
            
            obj.fitting_params_controller.load([folder 'fit_settings.xml']);
            obj.model_controller.load([folder 'fit_model.xml']);
            
            result_file = [folder 'fit_results.hdf5'];
            if isfile(result_file)
                obj.result_controller.load(result_file)
            end
            
        end
        
        
    end
        
end