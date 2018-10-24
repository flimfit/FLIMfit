function [pattern,name] = get_library_pattern

    if ~ispref('FLIMfit','pattern_library')
        errordlg('Pattern Library is empty','Error');
        return
    end
    
    pattern_library = getpref('FLIMfit','pattern_library');    
    keys = pattern_library.keys();
    
    if isempty(keys)
        warndlg('No patterns found, please create or import a pattern first','Pattern Library')
        ok = false;
    else
        [sel,ok] = listdlg('ListString',keys,'SelectionMode','single','Name','Pattern Library','PromptString','Select Pattern');
    end
    
    if ok
        name = keys{sel};
        pattern = pattern_library(name);
    else
        name = [];
        pattern = [];
    end
end