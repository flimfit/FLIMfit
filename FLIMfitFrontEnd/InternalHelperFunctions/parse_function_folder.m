function [funcs, params, defaults, descriptions, summaries] = parse_function_folder(folder)

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


    files = dir([folder filesep '*.m']);
    n_files = length(files);
    
    
    reg = 'function [^=]+\W*=\W*(.+)\([^,]+,\W*(.+)\)';

    params = cell(n_files,1);
    funcs = cell(n_files,1);
    defaults = cell(n_files,1);
    descriptions = cell(n_files,1);
    summaries = cell(n_files,1);
    
    
    for i=1:n_files
        file = [folder filesep files(i).name];
        fid = fopen(file);
        header = fgetl(fid);
        summary = fgetl(fid);
        def = fgetl(fid);
        
        desc = '';
        desc_line = fgetl(fid);
        while ~isempty(desc_line) && strcmp(desc_line(1),'%')
            desc = [desc desc_line];
            desc_line = fgetl(fid);
        end
        fclose(fid);
    
        tokens = regexp(header,reg,'tokens');
        if length(tokens) == 1
            tokens = tokens{1};
            funcs{i} = tokens{1};
            
            params_list = tokens{2};
            params_list = textscan(params_list,'%s','delimiter', ',');
            params_list = params_list{1};
            
            
            n_param = length(params_list);
            default_list = cell(n_param,1);
            desc_list = cell(n_param,1);
            for j=1:n_param
                
                df = regexp(def,['[,% ]' params_list{j} '=([\d\.-e]+)'],'tokens');
                de = regexp(desc,['[%;]' params_list{j} ',([^%]+)'],'tokens');
                
                if ~isempty(df)
                    default_list{j} = str2double(df{1});
                else
                    default_list{j} = 0;
                end
                if ~isempty(de)
                    de = de{1};
                    desc_list{j} = de{1};
                else
                    desc_list{j} = '';
                end
            end
            
            params{i} = params_list;
            descriptions{i} = desc_list;
            defaults{i} = default_list;
            summaries{i} = summary(2:end);
            
        else
        end
        
    end
        
end
