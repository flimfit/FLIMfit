function identify_flim_files(obj,root_path)

    if ~exist(root_path,'dir')
        throw(MException('FLIM:PathDoesNotExist','Path does not exist'));
    end

    root_path = ensure_trailing_slash(root_path);

    flim_files = cell(0);

    
    % Check for SDT files
    %-------------------------------------------------------------
    sdt_files = dir([root_path '*.sdt']);
        
    for i=1:length(sdt_files)
        [~,~,data_size] = LoadSDT(sdt_files(i).name,1,true); 
        flim_files(end+1) = ... 
            struct('DataType','TCSPC','Format','SDT','FileName',sdt_files(i).name,...
                   'DataSize',data_size); %#ok
    end
    
    % Check for TXT files
    %-------------------------------------------------------------
    sdt_files = dir([root_path '*.txt']);
        
    for i=1:length(txt_files)
        [~,~,data_size] = LoadSDT(sdt_files(i).name,1,true); 
        flim_files(end+1) = ... 
            struct('DataType','TCSPC','Format','TXT','FileName',sdt_files(i).name,...
                   'DataSize',data_size); %#ok
    end

end
