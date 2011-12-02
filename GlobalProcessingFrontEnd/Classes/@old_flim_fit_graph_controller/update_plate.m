function update_plate(obj)

    n_col = 12;
    n_row = 8;

    if obj.fit_controller.has_fit

        r = obj.fit_controller.fit_result;     
        n_im = length(r.images);

        md = r.metadata;
        
        if ~isfield(md,'Row') || ~isfield(md,'Column')
            set(obj.plate_axes,'XTick',[],'YTick',[],'Box','on');
            return
        end
        
        im_row = md.Row;
        im_col = md.Column;
        
        plate = zeros(n_row,n_col) * NaN;
        
        for row_idx = 1:n_row
            row = char(row_idx+64);
            for col = 1:n_col
                
                sel = strcmp(im_row,row) & cell2mat(im_col)==col;
                idx = 1:length(im_row);
                sel = idx(sel);
                
                y=[];
                
                for i=1:length(sel)
                    
                    if isfield(r.image_stats{sel(i)},obj.plate_param)
                        y(end+1) = r.image_stats{sel(i)}.(obj.plate_param).mean;
                    end
                end
                
                plate(row_idx,col) = mean(y);
                
            end
        end
        
        lims = r.default_lims.(obj.dep);
        
        m=2^16;
        plate = plate - lims(1);
        plate = plate / (lims(2) - lims(1));
        plate(plate > 1) = 1;
        plate(plate < 0) = 0;
        plate = plate * m + 1;
        plate(isnan(plate)) = 0;
        plate = int32(plate);
        cmap = jet(m);
        cmap = [ [1,1,1]; cmap];
        
        mapped_plate = ind2rgb(plate,cmap);
        
        
        imagesc(mapped_plate,'Parent',obj.plate_axes);
        set(obj.plate_axes,'YTickLabel',{'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'});
        set(obj.plate_axes,'XTick',0:1:n_col);
        set(obj.plate_axes,'TickLength',[0 0]);

        for i=1:n_col
            line([i+.5 i+.5],[0.5 n_row+.5],'Parent',obj.plate_axes,'Color','k');
        end
        for i=1:n_row
            line([0.5 n_col+.5],[i+.5 i+.5],'Parent',obj.plate_axes,'Color','k');
        end

        daspect([1,1,1]);

    else
        set(obj.plate_axes,'XTick',[],'YTick',[],'Box','on');


    end
end
