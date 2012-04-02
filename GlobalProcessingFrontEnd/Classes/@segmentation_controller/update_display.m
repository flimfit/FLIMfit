function update_display(obj)
    if ~isempty(obj.segmentation_axes) && ishandle(obj.segmentation_axes) && obj.data_series.init
        m = 256;

        selected = obj.data_series_list.selected;
        
        
        cim = obj.data_series_controller.selected_intensity(selected,false);
        lims = quantile(cim(:),[0.01 0.99]);
        mn = lims(1); mx = lims(2);
        cim = (cim-mn) / (mx-mn);
        cim(cim < 0) = 0;
        cim(cim > 1) = 1;
        cim = cim * m;

        mask = double(obj.mask(:,:,selected));
        cmask = (1 + mask/max(mask(:))) * m;

        alpha = 0.5*ones(size(mask));
        alpha(mask == 0) = 0;

        colormap(obj.segmentation_axes,[gray(m);jet(m)]);

        obj.segmentation_im = image(cim,'Parent',obj.segmentation_axes);
        hold(obj.segmentation_axes,'on');
        obj.mask_im = image(cmask,'Parent',obj.segmentation_axes, 'AlphaData',alpha);
        hold(obj.segmentation_axes,'off');
        
        set(obj.segmentation_axes,'XTick',[]);
        set(obj.segmentation_axes,'YTick',[]);

        obj.n_regions = max(mask(:));
        
        % find centroids for labels
        stats = regionprops(mask,'Centroid');
        
        for i=1:length(stats);
            c = stats(i).Centroid;
            text(c(1),c(2),num2str(i),'Parent',obj.segmentation_axes);
        end

        
    end

    if ishandle(obj.seg_results_table)
        table = {};
        for i=1:obj.n_regions

            m = obj.mask(:,:,obj.data_series_list.selected) == i;
            size_region = sum(m(:));
            row = {i size_region false};
            table = [table; row];

        end

        set(obj.seg_results_table,'Data',table);
    end
end