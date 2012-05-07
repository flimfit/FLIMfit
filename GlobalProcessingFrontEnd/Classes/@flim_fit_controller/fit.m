function fit(obj,varargin) %roi_mask,dataset,grid)
    
    bin = false;
    grid = false;
    roi_mask = [];
    dataset = [];

    if nargin == 2
        bin = varargin{1};
    elseif nargin >= 4
        bin = varargin{1};
        roi_mask = varargin{2};
        dataset = varargin{3};
        if nargin == 5
            grid = varargin{4};
        end
    end
    
    if obj.fit_in_progress && ~bin
        
        obj.fit_in_progress = false;
        obj.dll_interface.terminate_fit();
        obj.display_fit_end();
        obj.refit_after_return = false;
        
    elseif obj.fit_in_progress && bin
        
        obj.refit_after_return = true;
        
    else
        
        delete(obj.fit_result);
            
        obj.fit_in_progress = true;
        obj.has_fit = false;
        
        if ~bin
            obj.display_fit_start();
        end
        
        row_headers = {'Thread' 'Num Completed' 'Cur Group' 'Iteration' 'Chi2'};
        set(obj.progress_table,'RowName',row_headers);

        obj.start_time = tic;
        
        obj.fit_result = [];
        
        if bin == false
            err = obj.dll_interface.fit(obj.data_series_controller.data_series, obj.fit_params);
        else
            if isempty(roi_mask)
                roi_mask = obj.roi_controller.roi_mask;
            end
            if isempty(dataset)
                dataset = obj.data_series_list.selected;
            end
            
            err = obj.dll_interface.fit(obj.data_series_controller.data_series, obj.fit_params, roi_mask, dataset, grid);
        end
            
        if err ~= 0
            if err == -1005
                msgbox('Unable to allocate enough memory to process the fit requested. Reducing the number of threads may help, alternatively close any other open programs and restart Matlab.','Fitting Error','error');
            else
                msgbox(['An error code was returned from the fitting code ( ' num2str(err) ' )'],'Fitting Error','error');
            end
            
            obj.fit_in_progress = false;
            obj.display_fit_end();
            
        else
            
        end
        
    end
    
end