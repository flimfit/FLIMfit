classdef flim_fit_hist_controller < flim_fit_observer
   
    properties
        hist_axes;
        hist_param_popupmenu;
        hist_prop_table;
        
        hist_min = 0;
        hist_max = 1e3;
        hist_classes = 100;
        
        param;
        
        data_series_list;
        selected;
        
    end
    
    methods
        function obj = flim_fit_hist_controller(handles)
            obj = obj@flim_fit_observer(handles.fit_controller);
            assign_handles(obj,handles);
            
            set(obj.hist_prop_table,'CellEditCallback',@obj.table_updated);
            set(obj.hist_param_popupmenu,'Callback',@obj.param_updated);
            
            addlistener(obj.data_series_list,'selection_updated',@obj.selection_updated);
            
            obj.selected = obj.data_series_list.selected;
            
            obj.update_table();
            obj.update_param_list();
            obj.update_histogram();
        end
        
        function fit_update(obj)
            obj.update_param_list();
            obj.update_histogram();
        end
        
        function selection_updated(obj,~,~)
            obj.selected = obj.data_series_list.selected;
            obj.update_histogram();
        end
        
        function table_updated(obj,~,~)
            table_data = get(obj.hist_prop_table,'Data');
            obj.hist_min = table_data(1);
            obj.hist_max = table_data(2);
            obj.hist_classes = table_data(3);
            obj.update_histogram();
        end
        
        function update_param_list(obj)
            if obj.fit_controller.has_fit
                params = obj.fit_controller.fit_result.fit_param_list();
                set(obj.hist_param_popupmenu,'String',params);
                val = get(obj.hist_param_popupmenu,'Value');
                if val > length(params);
                    val = 1;
                end
                set(obj.hist_param_popupmenu,'Value',val);
                str = get(obj.hist_param_popupmenu,'String');
                obj.param = str{val};
                
            end
        end
        
        function param_updated(obj,~,~)
            val = get(obj.hist_param_popupmenu,'Value');
            str = get(obj.hist_param_popupmenu,'String');
            obj.param = str{val};
            
            table_data = get(obj.hist_prop_table,'Data');
            lims = obj.fit_controller.fit_result.default_lims.(obj.param);
            table_data(1:2) = lims;
            obj.hist_min = lims(1);
            obj.hist_max = lims(2);
            set(obj.hist_prop_table,'Data',table_data);
            
            obj.update_histogram();
            
        end
        
        function update_table(obj)
            table_data = zeros(3,1);
            table_data(1) = obj.hist_min;
            table_data(2) = obj.hist_max;
            table_data(3) = obj.hist_classes;
            
            set(obj.hist_prop_table,'Data',table_data);
        end
        
        function update_histogram(obj)
            if obj.fit_controller.has_fit && ~isempty(obj.param)
                param_data =  obj.fit_controller.fit_result.get_image(obj.selected,obj.param);
                %intensity = obj.fit_controller.fit_result.get_image(obj.selected,'I0');
                
                filt = param_data >= obj.hist_min & param_data <= obj.hist_max & ~isnan(param_data);
                
                %intensity = intensity( filt );
                param_data = param_data( filt );
                
                diff = (obj.hist_max - obj.hist_min) / obj.hist_classes;
                x = obj.hist_min:diff:obj.hist_max;
                
                
                %if ~isempty(param_data)
                %    f = ksdensity(param_data,x,'weight',intensity(:));
                %    plot(obj.hist_axes,x,f)
                %end
                
                cla(obj.hist_axes);
                hist(obj.hist_axes,param_data,x);
                set(obj.hist_axes,'XLim',[obj.hist_min obj.hist_max])
                xlabel(obj.hist_axes,obj.param);
                ylabel(obj.hist_axes,'Frequency');
            end
        end
        
        function export_histogram_data(obj,file,mode)
            
            if nargin < 3
                mode = 'single';
            end
            
            r = obj.fit_controller.fit_result;
            
            [path name ext] = fileparts(file);
            
            hist_min_v = zeros(1,r.n_results);
            hist_max_v = zeros(1,r.n_results);
            hist_mean = zeros(1,r.n_results);
            hist_std = zeros(1,r.n_results);
            hist_se = zeros(1,r.n_results);
            hist_area = zeros(1,r.n_results);
            
            count = zeros(obj.hist_classes+1,r.n_results);
            
            for i=1:r.n_results
               
                param_data =  obj.fit_controller.fit_result.get_image(i,obj.param);
                %intensity = obj.fit_controller.fit_result.get_image(obj.selected,'I0');
                
                filt = param_data >= obj.hist_min & param_data <= obj.hist_max & ~isnan(param_data);
                
                %intensity = intensity( filt );
                param_data = param_data( filt );
                
                diff = (obj.hist_max - obj.hist_min) / obj.hist_classes;
                x = obj.hist_min:diff:obj.hist_max;
       
                %count(:,i) = ksdensity(param_data,x,'weight',intensity(:));               
                count(:,i) = hist(param_data,x)';
                
                hist_min_v(i) = nanmin(param_data);
                hist_max_v(i) = nanmax(param_data);
                hist_mean(i) = nanmean(param_data);
                hist_std(i) = nanstd(param_data);
                hist_area(i) = sum(~isnan(param_data));
                hist_se(i) = hist_std(i)/sqrt(hist_area(i));
                
                if ~strcmp(mode,'single')
                    filename = [path filesep name ' ' hist_type ' histogram - ' r.names{i} ext];
                    f = fopen(filename,'w');

                    fprintf(f,'%s\r\n',r.names{i});
                    fprintf(f,'%s\r\n',hist_type);
                    fprintf(f,'Minimal value\t%f\r\n',hist_min_v(i));
                    fprintf(f,'Maximal value\t%f\r\n',hist_max_v(i));
                    fprintf(f,'Mean value\t%f\r\n',hist_mean(i));
                    fprintf(f,'Standard deviation\t%f\r\n',hist_std(i));
                    fprintf(f,'Standard error\t%f\r\n',hist_se(i));
                    fprintf(f,'Area (pixels)\t%f\r\n\r\n',hist_area(i));

                    fprintf(f,'%s\tNumber of Pixels\r\n',hist_type);

                    for j=1:length(x)
                        fprintf(f,'%f\t%f\r\n',x(j),count(:,i));
                    end

                    fclose(f);
                end
                
            end
            
            if strcmp(mode,'single')
                filename = [path filesep name ' ' obj.param ' histogram' ext];
                    f = fopen(filename,'w');

                    fprintf(f,'%s\r\n',obj.param);
                    for i=1:r.n_results
                        fprintf(f,'\t%s',r.names{i});
                    end
                    fprintf(f,'\r\nMinimal value');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_min_v(i));
                    end
                    fprintf(f,'\r\nMaximal value');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_max_v(i));
                    end
                    fprintf(f,'\r\nMean value');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_mean(i));
                    end
                    fprintf(f,'\r\nStandard deviation');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_std(i));
                    end
                    fprintf(f,'\r\nStandard error');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_se(i));
                    end
                    fprintf(f,'\r\nArea (pixels)');
                    for i=1:r.n_results
                        fprintf(f,'\t%f',hist_area(i));
                    end
                    fprintf(f,'\r\n\r\n');
                    fclose(f);
                    
                    table = [x' count];
                    
                    dlmwrite(filename,table,'-append','delimiter','\t','newline','pc');
                   
            end
            
        end
               
    end
    
end