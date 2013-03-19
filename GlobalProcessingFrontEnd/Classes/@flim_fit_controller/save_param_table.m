function save_param_table(obj,file)

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

    if obj.has_fit
        
        f = obj.fit_result;

        [data, row_headers] = obj.get_table_data();
        
        dat = [row_headers num2cell(data)];


        
        % Prepend meta data to table
        metadata = f.metadata;
                
        if ~isempty(metadata)   
            metadata_fields = fieldnames(metadata);
        else
            metadata_fields = [];
        end
        
        
        group = [];
        for i=1:f.n_results
            group = [group ones(1,length(f.regions{i}))*i];
        end
        
        for i=1:length(metadata_fields)
            md = metadata.(metadata_fields{i});
            dat = [[metadata_fields(i), md(group)]; dat];
        end
        
        cell2csv(file,dat,',');
        
    end
    
end