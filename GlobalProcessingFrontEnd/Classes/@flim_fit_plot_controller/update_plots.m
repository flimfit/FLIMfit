function update_plots(obj,file_root)

    if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end

    d = obj.fit_controller.data_series;
    
    if nargin == 2
        f_save = figure('visible','on');        
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
    else
        save = false;
    end

    n = ceil(sqrt(obj.n_plots));   
    m = ceil(obj.n_plots/n);

    if obj.n_plots>0 && ~save
        [ha,hc] = tight_subplot(obj.plot_panel,obj.n_plots,m,n,save,[d.width d.height],5,5,5);
    end
    
    if ~save
        im_start = obj.dataset_selected;
        im_end = obj.dataset_selected;
    else
        im_start = 1;
        im_end = d.n_datasets;
    end
    
    for cur_im = im_start:im_end

        if save
            name_root = [root ' ' d.names{cur_im}];
        end

        subplot_idx = 1;

        if obj.n_plots > 0

            for plot_idx = 1:length(obj.plot_names)
            
                if obj.display_normal.(obj.plot_names{plot_idx})
                    
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[d.width d.height]);
                    end
                    
                    im_data = obj.plot_figure(h,c,cur_im,obj.plot_names{plot_idx},false,'');
                    
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' char(obj.plot_names(plot_idx))],ext)
                        SaveFPTiff(im_data,[name_root ' ' char(obj.plot_names(plot_idx)) ' raw.tiff'])
                    end
                end

                % Merge
                if obj.display_merged.(obj.plot_names{plot_idx})
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[d.width d.height]);
                    end
                    
                    obj.plot_figure(h,c,cur_im,obj.plot_names{plot_idx},true,'');
                  
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' char(obj.plot_names(plot_idx)) ' merge'],ext)
                    end
                end
                
            end

        end      
    end
    
    if save
        close(f_save)
    end
end


%{
function update_plots(obj,file_root)

    if isempty(obj.fit_controller.fit_result) || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end

    if nargin == 2
        f_save = figure('visible','on');        
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
    else
        save = false;
    end

    d = obj.fit_controller.data_series;

    obj.update_plot_lims();

    r = obj.fit_controller.fit_result;

    n = ceil(sqrt(obj.n_plots));   
    m = ceil(obj.n_plots/n);

    if ~save
        ax=subplot(1,1,1,'Parent',obj.plot_panel);
        set(ax,'YTick',[]);
        set(ax,'XTick',[]);
    end


    if save
        im_start = 1;
        im_end = d.n_datasets;
    else
        im_start = obj.dataset_selected;
        im_end = obj.dataset_selected;
    end
    
    for cur_im = im_start:im_end

        if save
            name_root = [root ' ' d.names{cur_im}];
        end

        subplot_idx = 1;
%        mask = double(~obj.fit_controller.data_series_controller.selected_mask(cur_im));

        if obj.n_plots > 0

            intensity = d.selected_intensity(cur_im);

            for plot_idx = 1:length(obj.plot_names)
            
                if obj.display_normal.(obj.plot_names{plot_idx})
                    if ~save
                        h = subplot(m,n,subplot_idx,'Parent',obj.plot_panel);
                    else
                        figure(f_save);
                        clf(f_save);
                        h = axes();
                    end
                    %im_data = r.images{cur_im}.(obj.plot_names{plot_idx});
                    im_data = r.get_image(cur_im,obj.plot_names{plot_idx});
                    %im_data = eval(['r.' obj.plot_data{plot_idx}]);
                    %im_data = squeeze(im_data);
                    obj.custom_plot(h,im_data,intensity==0,obj.plot_lims.(obj.plot_names{plot_idx}),obj.plot_names(plot_idx));
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' char(obj.plot_names(plot_idx))],ext)
                        SaveFPTiff(im_data,[name_root ' ' char(obj.plot_names(plot_idx)) ' raw.tiff'])
                    end
                end

                % Merge
                if obj.display_merged.(obj.plot_names{plot_idx})
                    if ~save
                        h = subplot(m,n,subplot_idx,'Parent',obj.plot_panel);
                    else
                        figure(f_save);
                        clf(f_save);
                        h = axes();
                    end
                    %im_data = r.images{cur_im}.(obj.plot_names{plot_idx});
                    im_data = r.get_image(cur_im,obj.plot_names{plot_idx});
                    %im_data = eval(['r.' obj.plot_data{plot_idx}]);
                    %im_data = squeeze(im_data);
                    obj.custom_plot_merged(h,intensity,im_data,obj.plot_lims.(obj.plot_names{plot_idx}),obj.plot_lims.I0,obj.plot_names(plot_idx));
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' char(obj.plot_names(plot_idx)) ' merge'],ext)
                    end
                end
                
            end

        end      
    end
    
    if save
        close(f_save)
    end
end

%}