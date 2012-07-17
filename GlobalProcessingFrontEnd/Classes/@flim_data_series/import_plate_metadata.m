function import_plate_metadata(obj,file)

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
    
    notify(obj,'data_updated');
    
end