classdef flim_fit_hist_controller < abstract_plot_controller
   
    properties
        
        hist_weighting_popupmenu;
        hist_classes_edit;    
        hist_source_popupmenu;
        
    end
    
    methods
        function obj = flim_fit_hist_controller(handles)
            obj = obj@abstract_plot_controller(handles,handles.hist_axes,handles.hist_param_popupmenu);
            assign_handles(obj,handles);
            
            set(obj.hist_weighting_popupmenu,'Callback',@(~,~)obj.update_display);
            set(obj.hist_classes_edit,'Callback',@(~,~)obj.update_display);
            set(obj.hist_source_popupmenu,'Callback',@(~,~)obj.update_display);
            
            obj.update_display();
        end
        
        function draw_plot(obj,ax,param)
            cla(ax);

            
            
            if obj.fit_controller.has_fit && param > 0 && obj.selected > 0
                
                f = obj.fit_controller;
                r = f.fit_result;
                
                source = get(obj.hist_source_popupmenu,'Value');
                
                if source == 1
                    sel = obj.selected;
                    indexing = 'dataset';
                else
                    sel = obj.fit_controller.selected;
                    indexing = 'result';
                end
                
                weighting = get(obj.hist_weighting_popupmenu,'Value');
                hist_classes = str2double(get(obj.hist_classes_edit,'String'));
                
                param_data = [];
                I_data = [];
                md = [];
                for i=1:length(sel)
                    
                    
                    new_data = obj.fit_controller.get_image(sel(i),param,indexing);
                    new_I_data = obj.fit_controller.get_intensity(sel(i),indexing);
                        
                    filt = isfinite(new_data) & isfinite(new_I_data);
                    
                    
                    new_data = new_data(filt);
                    new_I_data = new_I_data(filt);
                    
                    %{
                    new_data = r.region_mean{sel(i)}(param,:)';
                    new_I_data = r.region_mean{sel(i)}(6,:)';
                    
                    
                    new_md = r.metadata.Column{sel(i)};
                    new_md = repmat(new_md,size(new_data));
                    md = [md; new_md];
                    %}

                    I_data = [I_data; new_I_data];
                    param_data = [param_data; new_data];
                   
                end
                %{
                s = 2:11;
                
                [a,b]=kmeans(param_data,2);
                for i=1:length(s)
                   
                    [~,ah] = max(b); 
                    
                    p(i) = sum(a(md==s(i))==ah)/sum(md==s(i));
                    
                    dat = param_data(a==ah & md==s(i));
                    qh(i) = mean(dat);
                    sh(i) = std(dat)/sqrt(length(dat));
                    
                    dat = param_data(a~=ah & md==s(i));
                    ql(i) = mean(dat);
                    sl(i) = std(dat)/sqrt(length(dat));
                    
                    
                end
                
                
                figure(12);
                %{
                plot(2*md(a==1),param_data(a==1),'xr');
                hold on;
                plot(2*md(a==2)+1,param_data(a==2),'xb');
                %}
                subplot(1,2,1);
                hold off
                errorbar(s,qh,sh,'r');
                hold on;
                errorbar(s,ql,sl,'b');
                xlim([2 10])
                xlabel('Dose');
                ylabel('Mean FRET fraction of each population')
                
                subplot(1,2,2);
                plot(s,p);
                ylim([0 0.5]);
                xlim([2 10]);
                xlabel('Dose');
                ylabel('Fraction of population responding');
                
                %}
               
                lims = f.get_cur_lims(param);
                I_lims = f.get_cur_intensity_lims;
                
                filt = param_data >= lims(1) & param_data <= lims(2);
                
                intensity = I_data( filt );
                param_data = param_data( filt );
                                
                intensity = (intensity - I_lims(1))/(I_lims(2)-I_lims(1));
                intensity(intensity<0) = 0;
                intensity(intensity>1) = 1;
                
                x = linspace(lims(1),lims(2),hist_classes);
                
                cla(ax);

                %[idx,c] = kmeans(param_data,2);
                
                %disp(c)
                
                %sum(idx==2)/length(idx)
                
                %disp([median(param_data) mean(param_data)]);
                
                if weighting == 2
                    weightedhist(ax,param_data,intensity,x);
                    
                else
                    hist(ax,param_data,x);
                    %[n,xout] = hist(param_data,x);
                    %bar(ax,xout,n);
                    %col = r.metadata.Column{sel(1)};
                    %csvwrite(['C:\Users\scw09\Documents\00 Local FLIM Data\2012-09-05 Ras-Raf Anca plate\hist\' num2str(col) '.csv'],[xout',n']);

                end
                
                if all(isfinite(lims))
                    set(ax,'XLim',lims)
                end
                xlabel(ax,r.latex_params{param});
                ylabel(ax,'Frequency');
            else
                cla(ax);
            end
        end
        
        function export_histogram_data(obj,file,mode)
            
            if obj.cur_param == 0
                return;
            end
            
            if nargin < 3
                mode = 'single';
            end
            
            f = obj.fit_controller;
            r = obj.fit_controller.fit_result;
            
            weighting = get(obj.hist_weighting_popupmenu,'Value');
            hist_classes = str2double(get(obj.hist_classes_edit,'String'));
            param = obj.cur_param;
            lims = f.get_cur_lims(param);
            
            if weighting == 2
                weighting_string = '(Intensity Weighted)';
            else
                weighting_string = '(Unweighted)';
            end
            
            
            
            [path name ext] = fileparts(file);
            
            hist_min_v = zeros(1,r.n_results);
            hist_max_v = zeros(1,r.n_results);
            hist_mean = zeros(1,r.n_results);
            hist_std = zeros(1,r.n_results);
            hist_se = zeros(1,r.n_results);
            hist_area = zeros(1,r.n_results);
            
                
            
            count = zeros(hist_classes,r.n_results);
            
            for i=1:r.n_results
               
                param_data =  obj.fit_controller.get_image_result_idx(i,param);
                
                if ~isempty(param_data)
                filt = param_data >= lims(1) & param_data <= lims(2) & ~isnan(param_data);
                
                param_data = param_data( filt );
                
                x = linspace(lims(1),lims(2),hist_classes);

                if ~isempty(param_data)
                    
                    if weighting == 2
                        intensity = obj.fit_controller.get_itensity_image_result_idx(i);
                        intensity = intensity( filt );

                        count(:,i) = weightedhist(param_data,intensity,x)';
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
                filename = [path filesep name ' ' r.params{param} ' histogram' ext];
                    f = fopen(filename,'w');

                    fprintf(f,'%s %s\r\n',r.params{param},weighting_string);
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