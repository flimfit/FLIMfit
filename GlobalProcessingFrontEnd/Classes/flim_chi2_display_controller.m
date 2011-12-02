classdef flim_chi2_display_controller < flim_fit_observer
    
    properties
        chi2_axes;
        display_factor_edit;
        calculate_button;
        
    end
    
    methods
        
        function obj = flim_chi2_display_controller(handles)
                       
            obj = obj@flim_fit_observer(handles.fit_controller);
            
            assign_handles(obj,handles);

            set(obj.calculate_button,'Callback',@obj.calculate_clicked);
            set(obj.display_factor_edit,'Callback',@obj.display_factor_change);
             
        end
        
        function fit_update(obj)
            obj.update_plot();
        end
        
        function display_factor_change(obj,~,~)
            obj.update_plot();
        end
        
        function update_plot(obj)
            p = obj.fit_controller.fit_params;
            f = obj.fit_controller.fit_result;
            
            fact = str2double(get(obj.display_factor_edit,'String'));
            if obj.fit_controller.has_fit && f.has_grid
                nx = size(f.grid,1);
                ny = size(f.grid,2);
               
                x = (1:nx)/nx * (p.tau_max(1) - p.tau_min(1)) +  p.tau_min(1);
                y = (1:ny)/ny * (p.tau_max(2) - p.tau_min(2)) +  p.tau_min(2);
                imagesc(x,y,f.grid,'Parent',obj.chi2_axes);
                
                mn = min(f.grid(f.grid>0))+1e-3;
                mx = max(f.grid(f.grid>0));
                lm = [mn mn*fact];
                
                caxis(obj.chi2_axes,lm);
                colorbar('peer',obj.chi2_axes);
                
            end
        end
        
        function calculate_clicked(obj,~,~)
            obj.fit_controller.fit(true,true);
            
        end
        
    end
    
end

