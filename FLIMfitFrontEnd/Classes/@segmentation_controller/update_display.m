function update_display(obj)

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren


    if ~isempty(obj.segmentation_axes) && ishandle(obj.segmentation_axes) && obj.data_series.init
        m = 256;

        selected = obj.data_series_list.selected;
        
        trim_outliers = get(obj.trim_outliers_checkbox,'Value');
        
        cim = obj.data_series_controller.selected_intensity(selected,false);
        
        d = obj.data_series_controller.data_series;
                
        if ~isempty(d.acceptor)
            aim = d.acceptor(:,:,selected);
        else
            aim = [];
        end
        
        cim(cim<0) = 0;
        aim(aim<0) = 0;
        
        if trim_outliers
            lims = quantile(cim(:),[0.01 0.99]);
            mn = lims(1); mx = lims(2);
        else
            mn = min(cim(:));
            mx = max(cim(:));
        end
            
        cim = (cim-mn) / (mx-mn);
        cim(cim < 0) = 0;
        cim(cim > 1) = 1;
        cim = cim * m;
        cim = uint8(cim);
        
        if obj.filtered_mask == 1
            mask_filtered = zeros(size(cim));
        else
            mask_filtered = double(obj.filtered_mask(:,:,selected));
        end
        
        if ~isempty(aim)
            if trim_outliers
                lims = quantile(aim(:),[0.01 0.99]);
                mn = lims(1); mx = lims(2);
            else
                mn = min(aim(:));
                mx = max(aim(:));
            end

            aim = (aim-mn) / (mx-mn);
            aim(aim < 0) = 0;
            aim(aim > 1) = 1;
            aim = aim * m;

            cim = [cim aim];
            cmask = [mask_filtered mask_filtered];
            
        else
            cmask = mask_filtered;
        end
               
        colors = lines(255);
         
        m = cmask > 0;
        m = repmat(m,[1 1 3]);
        
        cim = ind2rgb(cim,gray(255));
        cmask = ind2rgb(cmask,colors);
                
        im = cim;
        im(m) = (cim(m) + cmask(m)) / 2;
        
        set(obj.segmentation_im,'CData',im);
        set(obj.segmentation_axes,'XLim',[1 size(im,2)],'YLim',[1 size(im,1)]);
    
        obj.n_regions = max(mask_filtered(:));
        
        % find centroids for labels
        stats = regionprops(mask_filtered,'Centroid');
                
        delete(obj.labels);
        obj.labels = gobjects(size(stats));
        for i=1:length(stats)
            c = stats(i).Centroid;
            obj.labels(i) = text(c(1),c(2),num2str(i),'Parent',obj.segmentation_axes,...
                'Color','k','HorizontalAlignment','center','BackgroundColor','w');
        end

        
    end

    if ishandle(obj.seg_results_table)
        table = {};
        for i=1:obj.n_regions 
            m = obj.filtered_mask(:,:,obj.data_series_list.selected) == i;
            size_region = sum(m(:));
            row = {i size_region false};
            table = [table; row];
        end

        set(obj.seg_results_table,'Data',table);
    end
end