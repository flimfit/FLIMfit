function update_gallery(obj,file_root)
%{
    if nargin == 2
        f_save = figure('Position',get(0,'Screensize'),'Visible','off');        
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
        f = f_save;
    else
        f = obj.gallery_panel;
        save = false;
    end
    
    if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end

  
    
    image = get(obj.gallery_plot_popupmenu,'Value');
    image = obj.plot_names{image};
    
    overlay = get(obj.gallery_overlay_popupmenu,'Value');
    if overlay == 1
        overlay = [];
    else
        names = get(obj.gallery_overlay_popupmenu,'String');
        overlay = names{overlay};
    end
    
    unit = get(obj.gallery_unit_edit,'String');
    cols = str2double(get(obj.gallery_cols_edit,'String'));

    d = obj.fit_controller.data_series;
    n_im = d.n_datasets;

    rows = ceil(n_im/cols);
    
    if n_im>0
        [ha,hc] = tight_subplot(f,n_im,rows,cols,save,[d.width d.height],5,5);
        %ha = tight_subplot(obj.gallery_panel,n_im,rows,cols,0.005,0);
    end
    
    if ~strcmp(image,'-')

        if isempty(overlay);
            meta = [];
        else
            meta = d.metadata.(overlay);
        end
        
        for i=1:n_im
            if ~isempty(meta)
                text = meta{i};
                if strcmp(overlay,'s') && strcmp(unit,'min')
                    text = text / 60;
                end
                if ~ischar(text)
                    text = num2str(text);
                end
                text = [text ' ' unit];
            else
                text = '';
            end
 
            obj.plot_figure(ha(i),hc(i),i,image,false,text);
        end
        
        if save
            savefig([root ' ' image],f,ext);
        end
    end
    
    if save
        delete(f_save);
    end
%}
end