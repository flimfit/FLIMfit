classdef flim_fit_hist_controller < abstract_plot_controller
   
    properties
        
        hist_weighting_popupmenu;
        hist_classes_edit;        
        
    end
    
    methods
        function obj = flim_fit_hist_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.hist_axes,handles.hist_param_popupmenu);
            assign_handles(obj,handles);
            
            set(obj.hist_weighting_popupmenu,'Callback',@(~,~)obj.update_display);
            set(obj.hist_classes_edit,'Callback',@(~,~)obj.update_display);
            
            obj.update_display();
        end
        
        function draw_plot(obj,ax,param)
            cla(ax);

            
            
            if obj.fit_controller.has_fit && param > 0 && obj.selected > 0
                
                r = obj.fit_controller.fit_result;
                
                sel = obj.data_series_list.selected;
                %sel = obj.fit_controller.selected;
                
                weighting = get(obj.hist_weighting_popupmenu,'Value');
                hist_classes = str2double(get(obj.hist_classes_edit,'String'));
                
                param_data = [];
                for i=1:length(sel)
                    new_data = obj.fit_controller.get_image(sel(i),param);
                    new_data = new_data(isfinite(new_data));
                    param_data = [param_data; new_data];
                end
                
                lims = r.default_lims{param};
                
                filt = param_data >= lims(1) & param_data <= lims(2) & isfinite(param_data);
                
                param_data = param_data( filt );
                                
                x = linspace(lims(1),lims(2),hist_classes);
                
                cla(ax);

                if weighting == 2
                    intensity = obj.fit_controller.fit_result.get_image(obj.selected,'I');
                    intensity = intensity( filt );

                    weightedhist(ax,param_data,intensity,x);
                else
                    hist(ax,param_data,x);
                end
                
                if all(isfinite(lims))
                    set(ax,'XLim',lims)
                end
                xlabel(ax,param);
                ylabel(ax,'Frequency');
            end
        end
        
        function export_histogram_data(obj,file,mode)
            
            if nargin < 3
                mode = 'single';
            end
            
            weighting = get(obj.hist_weighting_popupmenu,'Value');
            
            if weighting == 2
                weighting_string = '(Intensity Weighted)';
            else
                weighting_string = '(Unweighted)';
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
               
                param_data =  obj.fit_controller.fit_result.get_image(i,param);
                
                if ~isempty(param_data)
                filt = param_data >= obj.hist_min & param_data <= obj.hist_max & ~isnan(param_data);
                
                param_data = param_data( filt );
                
                diff = (obj.hist_max - obj.hist_min) / obj.hist_classes;
                x = obj.hist_min:diff:obj.hist_max;
       
                if ~isempty(param_data)
                    
                    if weighting == 2
                        intensity = obj.fit_controller.fit_result.get_image(i,'I');
                        intensity = intensity( filt );

                        count(:,i) = weightedhist(ax,param_data,intensity,x)';
                    else
                        count(:,i) = hist(param_data,x)';
                    end
                else
                    param_data = NaN;
                end
                
                if weighting == 2
                    w_param_data = param_data.*intensity / mean(intensity(:));
                else
                    w_param_data = param_data;
                end
                
                hist_min_v(i) = nanmin(w_param_data);
                hist_max_v(i) = nanmax(w_param_data);
                hist_mean(i) = nanmean(w_param_data);
                hist_std(i) = nanstd(w_param_data);
                hist_area(i) = sum(~isnan(param_data));
                hist_se(i) = hist_std(i)/sqrt(hist_area(i));
                
                if ~strcmp(mode,'single')
                    filename = [path filesep name ' ' hist_type ' histogram - ' r.names{i} ext];
                    f = fopen(filename,'w');

                    fprintf(f,'%s %s\r\n',r.names{i},weighting_string);
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
                
            end
            
            if strcmp(mode,'single')
                filename = [path filesep name ' ' obj.cur_param ' histogram' ext];
                    f = fopen(filename,'w');

                    fprintf(f,'%s %s\r\n',obj.cur_param,weighting_string);
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