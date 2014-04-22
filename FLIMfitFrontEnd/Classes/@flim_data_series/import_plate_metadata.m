function import_plate_metadata(obj,file)

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

    [~,~,ext] = fileparts(file);
    
    if strcmp(ext,'.csv')
        
        f=fopen(file);
        l=fgetl(f);
        headers=strsplit(l,',');
        
        if length(headers) < 2
            warning('Not enough columns')
            return
        end
        idx_h = headers{1};
        isn = all(cellfun(@isnumeric,obj.metadata.(idx_h)));
        if isn 
            h = cell2mat(obj.metadata.(idx_h));
        else
            h = obj.metadata.(idx_h);
        end
        
        for i=2:length(headers)
            headers{i} = strtrim(headers{i});
            obj.metadata.(headers{i}) = cell(1,obj.n_datasets);
        end
        
        l=fgetl(f);
        while ischar(l)
            dat = strsplit(l,',');
            
            for i=2:length(headers)
                if isn
                    sel = h == str2double(dat{1});
                else
                    sel = strcmp(h,dat{1});
                end
                if any(sel)
                    if ~isempty(str2double(dat(i)))
                        obj.metadata.(headers{i}){sel} = str2double(dat{i});
                    else
                        obj.metadata.(headers{i})(sel) = dat(i);
                    end
                end
            end
            
            l=fgetl(f); 
        end
        
        fclose(f);
        
    else

        [status,sheets]=xlsfinfo(file);

        if strcmp(status,'') 
            return;
        end

        if ~isfield(obj.metadata,'Well')
            disp('Current metadata does not contain wells');
        end

        md_well = obj.metadata.Well;

        for i=1:length(sheets)

            sheet = sheets{i};

            [num,txt,raw]=xlsread(file,sheet);

            if ~strcmp(sheet,'Sheet1') && ~strcmp(sheet,'Sheet2') && ~strcmp(sheet,'Sheet3')
                sheet = strrep(sheet,'-','_');
                sheet = strrep(sheet,'.','_');
                sheet = strrep(sheet,' ','_');

                rows = size(raw,1)-1;
                cols = size(raw,2)-1;

                new_md = cell(size(md_well));

                for row_idx = 1:rows
                    row = char(row_idx+64);
                    for col = 1:cols

                        well = [row num2str(col)];
                        sel = strcmp(md_well,well);
                        new_md(sel) = raw(row_idx+1,col+1);


                    end
                end



                obj.metadata.(sheet) = new_md;
            end
        end
       
    end
    
    notify(obj,'data_updated');
    
end