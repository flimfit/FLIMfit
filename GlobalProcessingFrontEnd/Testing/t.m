function args_to_struct(varargin)
    fieldnames = varargin(1:2:end);
    cellarray = varargin(2:2:end);
    
    cell2struct(cellarray(:),fieldnames(:),1);