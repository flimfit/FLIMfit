function add_Original_Metadata_Annotation(session,image,full_filename)

        bfdata = bfopen(full_filename);
        metadata = bfdata{1, 2}; % place for original metadata :)         
        if isempty(metadata), return, end;
        if 0==metadata.size(), return, end;
        %
            detached_metadata_filename = [tempdir 'original_metadata.txt'];
            fid = fopen(detached_metadata_filename,'w');    
            %
                metadataKeys = metadata.keySet().iterator();
                for i=1:metadata.size()
                    key = metadataKeys.nextElement();
                    value = metadata.get(key);
                    if isnumeric(value)
                        if value == floor(value)
                            format = '%s=%d\r\n';
                        else
                            format = '%s=%e\r\n';
                        end
                    else
                        format = '%s=%s\r\n';
                    end
                    fprintf(fid,format, key, value);
                end                                    
            fclose(fid);                
        namespace = 'ORIGINAL_METADATA_NS';        
        description = ' ';        
        sha1 = char('pending');
        file_mime_type = char('application/octet-stream');        
        add_Annotation(session, ...
                        image, ...
                        sha1, ...
                        file_mime_type, ...
                        detached_metadata_filename, ...
                        description, ...
                        namespace);            
                    
end

