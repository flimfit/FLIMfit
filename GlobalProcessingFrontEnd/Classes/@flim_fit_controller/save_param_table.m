function save_param_table(obj,file,append,save_images)

    if ~exist('append','var') || append == false
        write_mode = 'w';
        already_exists = false;
    else
        write_mode = 'a';
        already_exists = exist(file,'file');
    end
    
    if ~exist('save_images','var')
        save_images = false;
    end

    if obj.has_fit
        
        f = obj.fit_result;
        
        if save_images
            param_list = f.fit_param_list;
        else
            param_list = [];
        end
        
        %fid=fopen(file,write_mode);

        rows=size(obj.param_table,1);

        metadata = f.metadata;
                
        if ~isempty(metadata)   
            metadata_fields = fieldnames(metadata);
        else
            metadata_fields = [];
        end
        
        dat = [obj.param_table_headers, num2cell(obj.param_table)]';
        
        group = [];
        for i=1:f.n_results
            group = [group ones(1,length(f.regions{i}))*i];
        end
        
        for i=1:length(metadata_fields)
            md = metadata.(metadata_fields{i});
            dat = [[metadata_fields(i), md(group)]',dat];
        end
        
        cell2csv(file,dat,',');
        
        %{
        if ~already_exists
            fprintf(fid,'id,');
            fprintf(fid,'file,');
            for i=1:length(metadata_fields)
                fprintf(fid,'%s,',metadata_fields{i});
            end
            for i=1:length(param_list)
                fprintf(fid,'%s_image_file,%s_image_dir,',param_list{i},param_list{i});
            end
            fprintf(fid,'Plate,');
            fprintf(fid,'%s,',obj.param_table_headers{1:end-1});
            fprintf(fid,'%s\r\n',obj.param_table_headers{end});
        end
        
        %fprintf(fid,'%f,',im_group);
        %fprintf(fid,'%f,',obj.fit_result.datasets(end));
        
        fprintf(fid,'%s,',obj.fit_result.names(1:end-1));
        fprintf(fid,'%s,',obj.fit_result.names(end));
        
        for j=1:length(metadata_fields)
            if isnumeric(metadata.(metadata_fields{j}){im_group})
                fprintf(fid,'%f,',metadata.(metadata_fields{j}){1:end-1});
                fprintf(fid,'%f,',metadata.(metadata_fields{j}){end});
            else
                fprintf(fid,'%s,',metadata.(metadata_fields{j}){1:end-1});
                fprintf(fid,'%s,',metadata.(metadata_fields{j}){end});
            end
        end
        
        for i=1:rows

            
            %for j=1:length(param_list)
             %   fprintf(fid,'%s %s.tif,images,',obj.fit_result.names{i},param_list{j});
            %end
            fprintf(fid,'1,');
            fprintf(fid,'%f,',obj.param_table(i,1:end-1));
            fprintf(fid,'%f\r\n',obj.param_table(i,end));
        end

        fclose(fid);
        %}
    end
    
end