function update_plots(obj,file_root)

    children = get(obj.plot_panel,'Children');
    if ~isempty(children)
        for i=1:length(children)
            delete(children(i))
        end
    end
    
    if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end
    
    f = obj.fit_controller;
    r = f.fit_result;
        
    
    if nargin == 2
        f_save = figure('visible','on');        
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
    else
        save = false;
    end

    if ~save && obj.dataset_selected == 0;
        return
    end;
    
    n = ceil(sqrt(f.n_plots));   
    m = ceil(f.n_plots/n);

  
    if f.n_plots>0 && ~save
        [ha,hc] = tight_subplot(obj.plot_panel,f.n_plots,m,n,save,[r.width r.height],5,5,5);
    end
    
    if ~save
        ims = obj.dataset_selected;
    else
        ims = 1:r.n_results;
    end
    
    for cur_im = ims

        if save
            name_root = [root ' ' r.names{cur_im}];
        end

        subplot_idx = 1;

        if f.n_plots > 0

            for plot_idx = 1:length(f.plot_names)
            
                if f.display_normal.(f.plot_names{plot_idx})
                    
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    end
                    
                    im_data = obj.plot_figure(h,c,cur_im,obj.plot_names{plot_idx},false,'');
                    
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' r.params{plot_idx}],ext)
                        SaveFPTiff(im_data,[name_root ' ' r.params{plot_idx} ' raw.tiff'])
                    end
                end

                % Merge
                if f.display_merged.(f.plot_names{plot_idx})
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    end
                    
                    obj.plot_figure(h,c,cur_im,obj.plot_names{plot_idx},true,'');
                  
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' r.params{plot_idx} ' merge'],ext)
                    end
                end
                
            end

        end      
    end
    
    if save
        close(f_save)
    end
end

