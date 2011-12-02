function update_graph(obj,mode)

    if nargin < 2
        mode = 'display';
    end
    
    powerpoint = strcmp(mode,'powerpoint');
    

    if obj.fit_controller.has_fit && ~isempty(obj.ind)

        if powerpoint
            f = figure('Visible','off');
            ax = axes();
        else
            ax = obj.graph_axes;
        end

        r = obj.fit_controller.fit_result;     

        mask = obj.roi_controller.roi_mask;
        
        err_name = [obj.dep '_err'];

        if ~any(strcmp(obj.dep_vars,err_name))
            err_name = [];
        end
                
        n_im = length(r.images);


        md = r.metadata.(obj.ind);

        var_is_numeric = all(cellfun(@isnumeric,md));

        if var_is_numeric
            x_data = cell2mat(md);
            x_data = unique(x_data);
            x_data = sort(x_data);
        else
            x_data = unique(md);
            x_data = sort(x_data);
        end

        for i=1:length(x_data)
            y = 0; yv = 0; yn = 0; e = 0; ymask = [];
            for j=1:n_im
                if (var_is_numeric && md{j} == x_data(i)) || (~var_is_numeric && strcmp(md{j},x_data{i}))
                    
                    n = r.image_stats{j}.(obj.dep).n;
                    y = y + r.image_stats{j}.(obj.dep).mean * n; 
                    yv = yv + (r.image_stats{j}.(obj.dep).std)^2*n;
                    yn = yn + r.image_stats{j}.(obj.dep).n;
                    if ~isempty(err_name)
                        e = e + r.image_stats{j}.(err_name).mean * n;
                    end
                    
                    %{
                    ym = r.get_image(j,obj.dep);
                    ym = ym(mask);
                    ymask = [ymask; ym];
                    %}
                    
                end
            end
            y_data(i) = y/yn;
            y_err(i) = sqrt(yv/yn); % 95% conf interval ~2*standard error 
            err(i) = e/yn;
            
            %y_mean_data(i) = nanmean(ymask);

        end
        
        if ~all(err==0) && ~all(isnan(err))
            y_err = err;
        end
        
        if var_is_numeric
            errorbar(ax,x_data,y_data,y_err,'o-');
        else
            errorbar(ax,y_data,y_err,'o-');
            set(ax,'XTick',1:length(y_data));
            set(ax,'XTickLabel',x_data);
        end

        ylabel(ax,obj.dep);
        xlabel(ax,obj.ind);
        
        if powerpoint
            pptfigure(f,'SlideNumber','append');
            close(f);
        end
    end
end
