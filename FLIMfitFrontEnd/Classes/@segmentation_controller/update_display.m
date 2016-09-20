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
        
        if obj.filtered_mask == 1
            mask_filtered = zeros(size(cim));
            mask = zeros(size(cim));
            bmask = zeros(size(cim));
        else
            mask_filtered = double(obj.filtered_mask(:,:,selected));
            mask = double(obj.mask(:,:,selected));
    
            bmask = mask > 0;
            se = strel('disk',1);
            bmaske = imerode(bmask,se);
            bmask = bmask & ~bmaske;
        end
            
            
        alpha = 0.5*ones(size(mask_filtered));
        alpha(mask_filtered == 0) = 0;
        
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

            cim = [cim; aim];
            cmask = [mask_filtered; mask_filtered];
            
            bmask = [bmask; bmask];
            alpha = [alpha; alpha];
            
        else
            cmask = mask_filtered;
        end
                        
        cmask = (1 + cmask/max(cmask(:))) * m + 1;
 
        colormap(obj.segmentation_axes,[gray(m);[1 0 0];jet(m)]);

        obj.segmentation_im = image(cim,'Parent',obj.segmentation_axes);
        hold(obj.segmentation_axes,'on');
        
        image(ones(size(bmask))*(m+1),'Parent',obj.segmentation_axes,'AlphaData',bmask);
        obj.mask_im = image(cmask,'Parent',obj.segmentation_axes, 'AlphaData',alpha);
        obj.paint_im = image(ones([size(cmask) 3]), 'AlphaData',zeros(size(cmask)));
        hold(obj.segmentation_axes,'off');
        
        set(obj.segmentation_axes,'XTick',[],'YTick',[]);
        daspect(obj.segmentation_axes,[1 1 1]);
    
        obj.n_regions = max(mask_filtered(:));
        
        % find centroids for labels
        stats = regionprops(mask_filtered,'Centroid');
        
        if get(obj.white_text_checkbox,'Value')
            text_col = 'w';
        else
            text_col = 'k';
        end
        
       colors = jet(length(stats));
       for i=1:length(stats)
            c = stats(i).Centroid;
            text_col = 1-colors(i,:);
            
            if (mean(colors(i,:))) < 0.6
                text_col = 'w';
            else 
                text_col = 'k';
            end
            
            text(c(1),c(2),num2str(i),'Parent',obj.segmentation_axes,'Color',text_col,'HorizontalAlignment','center');
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