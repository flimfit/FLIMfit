 classdef flim_fit_plot_controller < flim_fit_observer
   
    properties
        plot_select_table;
        plot_panel;
        %{
        gallery_panel;
        gallery_plot_popupmenu;
        gallery_cols_edit;
        gallery_overlay_popupmenu;
        gallery_unit_edit;
        %}
        dataset_selected = 1;
        
        n_plots = 0;
        display_normal = struct();
        display_merged = struct();
        plot_names = {};
        plot_data;
        default_lims = struct();
        plot_lims = struct();
        auto_lim = struct();
        
        data_series_list;
        lh = {};
    end
    
    properties(Access='protected')
        n_exp_list = 0;
        n_fret_list = 0;
        inc_Rinf_list = 0;
    end
    
    methods
       
        function obj = flim_fit_plot_controller(handles)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            assign_handles(obj,handles);

            set(obj.plot_select_table,'CellEditCallback',@obj.plot_select_update);
            
            addlistener(obj.plot_panel,'Position','PostSet',@obj.panel_resized);
            addlistener(obj.data_series_list,'selection_updated',@obj.dataset_selected_update);
            %{
            set(obj.gallery_plot_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_cols_edit,'Callback',@obj.gallery_params_update);
            set(obj.gallery_overlay_popupmenu,'Callback',@obj.gallery_params_update);
            set(obj.gallery_unit_edit,'Callback',@obj.gallery_params_update);
                        
            %}
            obj.update_list();
            obj.update_table();
            
        end
        
        function export_plots(obj,file_root)
            obj.update_plots(file_root);
        end
        
        
        function panel_resized(obj,~,~)
            obj.update_plots();
            %obj.update_gallery();
        end
        
        function lims = get_lims(~,var)
            var = var(:);
            lims = [min(var) max(var)];
        end
        
        
        function dataset_selected_update(obj,src,~)
            obj.dataset_selected = src.selected;
            obj.update_plots();
        end
        
        function plot_select_update(obj,~,~)
            plots = get(obj.plot_select_table,'Data');

            obj.n_plots = 0;
            
            for i=1:size(plots,1)
               name = plots{i,1};
               obj.display_normal.(name) = plots{i,2};
               obj.display_merged.(name) = plots{i,3};
               
               obj.n_plots = obj.n_plots + sum(cell2mat(plots(i,2:3))); 
               
               obj.auto_lim.(name) = plots{i,6};
               obj.plot_lims.(name) = cell2mat(plots(i,4:5));           
            end
            
            obj.update_table();
            obj.update_plots();
            
        end
        
        function fit_update(obj)
            if ishandle(obj.plot_panel) %check object hasn't been closed
                obj.update_list();
                obj.update_table();
                obj.update_plots();
                %obj.update_gallery();
            end
        end
        
        function update_table(obj)
                       
            if obj.fit_controller.has_fit
                r = obj.fit_controller.fit_result;
                names = obj.plot_names;
                table = cell(length(names),6);
                for i=1:length(names)
                    if obj.auto_lim.(names{i})
                        im_data = r.get_image(1,names{i});
                        mn = floor(nanmin(im_data(:)));
                        mx = ceil(nanmax(im_data(:)));
                        obj.plot_lims.(names{i}) = [mn mx];
                    end
                    
                    table{i,1} = names{i};
                    table{i,2} = obj.display_normal.(names{i});
                    table{i,3} = obj.display_merged.(names{i});
                    table(i,4:5) = num2cell(obj.plot_lims.(names{i}));
                    table{i,6} = obj.auto_lim.(names{i});
                end
                
                r.default_lims = obj.plot_lims;
                
                set(obj.plot_select_table,'Data',table);
                set(obj.plot_select_table,'ColumnEditable',logical([0 1 1 1 1 1]));
                set(obj.plot_select_table,'RowName',[]);
                
                %set(obj.gallery_plot_popupmenu,'String',names);
                
                %metafields = fieldnames(r.metadata);
                
                %set(obj.gallery_overlay_popupmenu,'String',['-' metafields']);
            end
        end
        %{
        function gallery_params_update(obj,~,~)
           
            cols = round(str2double(get(obj.gallery_cols_edit,'String')));
            set(obj.gallery_cols_edit,'String',num2str(cols));
            
            obj.update_gallery();
            
        end
        %}
                
    end
    
end