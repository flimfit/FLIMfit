function pattern_library_ui

f = figure('Name','Pattern Library','MenuBar','none','Toolbar','none','NumberTitle','off');

layout = uix.HBox('Parent',f,'Padding',5,'Spacing',5);
left_layout = uix.VBox('Parent',layout,'Spacing',5);
handles.list = uicontrol(left_layout,'Style','listbox','Callback',@(~,~) list_updated,'Min',0,'Max',2);

uicontrol(left_layout,'Style','pushbutton','String','Rename','Callback',@(~,~) rename_pattern);
uicontrol(left_layout,'Style','pushbutton','String','Remove','Callback',@(~,~) remove_pattern);

right_layout = uix.VBox('Parent',layout,'Spacing',5);

handles.panel = uipanel(right_layout);

layout.Widths = [200 -1];
left_layout.Heights = [-1 22 22];
right_layout.Heights = [-1];

ax = axes('Parent',handles.panel,'Box','off','TickDir','out');

file_menu = uimenu(f,'Label','File');
uimenu(file_menu,'Label','Export Selected Patterns...','Callback', @(~,~) export_patterns);
uimenu(file_menu,'Label','Import Selected Patterns...','Callback', @(~,~) import_patterns);

get_patterns();
list_updated();


    function pattern_library = get_pattern_library()
        pattern_library = getpref('FLIMfit','pattern_library',containers.Map('KeyType','char','ValueType','any'));
    end

    function [pattern,name,pattern_library] = get_current_pattern()
        pattern = [];
        name = '';
        
        pattern_library = get_pattern_library();
        if handles.list.Value <= length(handles.list.String)
            name = handles.list.String{handles.list.Value};
            if pattern_library.isKey(name)
                pattern = pattern_library(name);
            else
                name = '';
            end
        end
    end

    function list_updated(~,~)
        
        [pattern] = get_current_pattern();
        
        if ~isempty(pattern)
            T = 12500;
            dt = 25;
            t = 0:dt:(T-dt);
            mu = 2000;
            sigma = 100;
            
            decay = [];
            for i=1:size(pattern,2)
                ch = pattern(:,i);
                offset = ch(end);
                ch = ch(1:end-1);
                ch = reshape(ch,[2 length(ch)/2]);
                tau = ch(1,:);
                beta = ch(2,:);
                
                dc = offset;
                for j=1:length(tau)
                    dc = dc + beta(j) * generate_decay_analytical_irf(t, dt, T, tau(j), mu, sigma);
                end
                decay(:,i) = dc;
            end
            
            plot(ax,t,decay);
            xlim(ax,[0 T]);
            set(ax,'Box','off','TickDir','out');
        else
            handles.list.Value = length(handles.list.String);
        end
    end

    function get_patterns()
        [~,name,pattern_library] = get_current_pattern();
        patterns = pattern_library.keys;
        
        handles.list.String = patterns;
        idx = find(strcmp(patterns,name),1);
        if ~isempty(idx)
            handles.list.Value = idx;
        end
        if handles.list.Value > length(handles.list.String)
            handles.list.Value = 1;
        end
    end

    function rename_pattern
        [pattern,name,pattern_library] = get_current_pattern();
        new_name = inputdlg('Pattern Name','Pattern Name',1,{name});
        
        if ~isempty(new_name)
            pattern_library(new_name{1}) = pattern;
            pattern_library.remove(name);
        end
        
        setpref('FLIMfit','pattern_library',pattern_library);
        get_patterns();
    end

    function remove_pattern
        sel = handles.list.Value;
        if sel(1) <= length(handles.list.String)
            choice = questdlg('Are you sure you want delete the selected patterns?','Confirm Delete','Delete','Cancel','Delete');
            if strcmp(choice,'Delete')
                [~,~,pattern_library] = get_current_pattern();
                for i=1:length(sel)
                    pattern_library.remove(handles.list.String{sel(i)});
                end
                setpref('FLIMfit','pattern_library',pattern_library);
            end
        end
        get_patterns();
    end

    function export_patterns
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
        [file,path] = uiputfile('*.json','Choose File',[default_path 'pattern_library.json']);
        if file ~= 0
            pattern_library = get_pattern_library();
            keys = pattern_library.keys;
            lib = struct('name',{},'pattern',{});
            for i=1:length(keys)
                lib(i).name = keys{i};
                lib(i).pattern = pattern_library(keys{i});
            end
            
            json_data = jsonencode(lib);
            f = fopen([path file],'w');
            fprintf(f,json_data);
            fclose(f);
        end
    end

    function import_patterns
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
        [file,path] = uigetfile('*.json','Choose File',default_path);
        
        
        if file ~= 0
            pattern_library = get_pattern_library();
            json_data = fileread([path file]);
            lib = jsondecode(json_data);
            assert(isstruct(lib) && isfield(lib,'name') && isfield(lib,'pattern'));
            
            for i=1:length(lib)
                pattern_library(lib(i).name) = lib(i).pattern;
            end
            
            setpref('FLIMfit','pattern_library',pattern_library);    
            get_patterns();
        end
    end

end