function [pattern,name] = get_library_pattern

    if ~ispref('FLIMfit','pattern_library')
        errordlg('Pattern Library is empty','Error');
        return
    end
    
    pattern_library = getpref('FLIMfit','pattern_library');    
    keys = pattern_library.keys();
    
    
    [sel,ok] = listdlg('ListString',keys,'SelectionMode','single','Name','Pattern Library','PromptString','Select Pattern');
    
    if ok
        name = keys{sel};
        pattern = pattern_library(name);
    else
        name = [];
        pattern = [];
    end
end