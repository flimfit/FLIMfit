function s = args2struct(args)
    if length(args) > 1
        fieldnames = args(1:2:end);
        cellarray = args(2:2:end);
        s=cell2struct(cellarray(:),fieldnames(:),1);
    elseif isempty(args)
        s = struct();
    else
        s = args{1};
    end
end