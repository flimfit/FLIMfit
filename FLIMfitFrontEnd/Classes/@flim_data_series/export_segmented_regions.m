function export_segmented_regions(obj, path)

    for i=1:obj.n_datasets
        obj.switch_active_dataset(i, true);
        
        if isempty(obj.seg_mask)
            mask = ones(obj.height, obj.width);
        else
            mask = obj.seg_mask(:,:,i);            
        end
        
        if ~isempty(obj.multid_mask)
            mask(~obj.multid_mask(:,:,i)) = 0;
        end
        
        n = max(mask(:));
        
        for j=1:n
            data = obj.cur_tr_data(:,:,mask == j);
            data = mean(data,3);
            
            filename = [path filesep obj.names{i} '_R' num2str(j,'%03i') '.csv'];
                        
            f = fopen(filename,'w');
            fwrite(f,'T');
            for k=1:size(data,2)
                fwrite(f,[', Ch' num2str(k)]);
            end
            fprintf(f,'\n');
            fclose(f);
            
            data = [obj.tr_t', data]; %#ok
            
            dlmwrite(filename,data,'-append');
            
        end

        
    end

end

