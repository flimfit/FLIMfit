function filter_table_updated(obj,~,~)


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


    data = get(obj.filter_table,'Data');

    sel = true(1,obj.fit_result.n_results);
    
    md = obj.fit_result.metadata;
    
    for i=1:size(data,1)
       
        if all(cellfun(@isempty,data(i,:)))==0 && ~strcmp(data{i,1},'-') && isfield(md,data{i,1})
            
            field = data{i,1};
            op_str = data{i,2};
            val = data{i,3};
            
            m = md.(field);
            var_is_numeric = all(cellfun(@isnumeric,m));

            if var_is_numeric
                
                m = cell2mat(m);
                val = str2double(val);
                
                switch op_str
                    case '='
                        op = @eq;
                    case '!='
                        op = @ne;
                    case '<'
                        op = @lt;
                    case '>'
                        op = @gt;
                    otherwise
                        op = [];
                end
                
                if ~isempty(op)
                    sel = sel & op(m,val);
                end
            else
                
                switch op_str
                    case '='
                        op = @strcmp;
                    case '!='
                        op = @(x,y) (1-strcmp(x,y));
                    otherwise
                        op = [];
                end
                
                if ~isempty(op)
                    sel = sel & cellfun(@(x)op(val,x),m);
                end
                
            end
            
           
            
        end
        
    end

    nempty = cell2mat(obj.fit_result.image_size);
    nempty = nempty > 0;
    
    new_selected = 1:obj.fit_result.n_results;
    new_selected = new_selected(sel & nempty);

    changed = length(new_selected)~=length(obj.selected) || ~all(new_selected==obj.selected);
       
    obj.selected = new_selected;
    
    if changed
        notify(obj,'fit_display_updated');
    end
end