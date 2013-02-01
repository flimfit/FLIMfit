 classdef flim_fit_plot_controller < flim_fit_observer
   
    properties
        
        dataset_selected = 1;       
        plot_panel;
    
        n_plots = 0;
        
        data_series_list;
        lh = {};
    end
    
    properties(Access='protected')
        n_exp_list = 0;
        n_fret_list = 0;
        inc_donor_list = 0;
    end
    
    methods
       
        function obj = flim_fit_plot_controller(handles)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            assign_handles(obj,handles);
            
            addlistener(obj.plot_panel,'Position','PostSet',@obj.panel_resized);
            addlistener(obj.data_series_list,'selection_updated',@obj.dataset_selected_update);
            
        end
        
        function export_plots(obj,file_root)
            obj.update_plots(file_root);
        end
        
        
        function panel_resized(obj,~,~)
            obj.update_plots();
        end
        
        function lims = get_lims(~,var)
            var = var(:);
            lims = [min(var) max(var)];
        end
        
        
        function dataset_selected_update(obj,src,~)          
            obj.dataset_selected = src.selected;
            obj.update_plots();
        end
        
        function fit_update(obj)
            if ishandle(obj.plot_panel) %check object hasn't been closed
                obj.update_plots();
            end
        end
        
        function fit_display_update(obj)
            if ishandle(obj.plot_panel) %check object hasn't been closed
                obj.update_plots();
            end
        end
 
    end
    
end