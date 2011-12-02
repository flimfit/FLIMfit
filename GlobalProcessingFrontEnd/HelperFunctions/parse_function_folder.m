function [funcs, params] = parse_function_folder(folder)

    files = dir([folder '\*.m']);
    n_files = length(files);
    
    
    reg = 'function [^=]+\W*=\W*(.+)\([^,]+,\W*(.+)\)';

    params = cell(0);
    funcs = cell(0);
    
    for i=1:n_files
        file = [folder filesep files(i).name];
        fid = fopen(file);
        header = fgetl(fid);
        fclose(fid);
    
        tokens = regexp(header,reg,'tokens');
        if length(tokens) == 1
            tokens = tokens{1};
            funcs = [funcs tokens{1}];
            
            params_list = tokens{2};
            params_list = textscan(params_list,'%s','delimiter', ',');
            params = [params params_list];
        else
        end
        
    end
        
end
