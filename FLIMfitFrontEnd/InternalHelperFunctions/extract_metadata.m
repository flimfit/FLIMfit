function metadata = extract_metadata(strings,metadata)

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


    strrep(strings,filesep,' ');
    strrep(strings,'.','_');
    
try 
    
    if nargin < 2
        metadata = struct();
    end
    
    if nargin < 1
        strings = {'Test t=1.0min x=4 type=gfp' 'Test t=2.0min x=3'};
    end

    n = length(strings);
        
    for i=1:length(strings)
        strings{i} = strrep(strings{i},'.ome','');
        strings{i} = strrep(strings{i},'.OME','');
    end
    
    common_substring = strings{1};
 
    for i=1:n
        s = strings{i};
        
        % Get trailing rep numbers
        [match,tokens] = regexp(s,'_(\d+)_(\d+)$','match','tokens','once');
        if ~isempty(tokens)
            add_class('Rep1');
            add_class('Rep2');
            metadata.Rep1{i} = str2double(tokens{1});
            metadata.Rep2{i} = str2double(tokens{2});
            
            s = strrep(s,match,'');
        end
        
        % Look for Well= indicator
        [tokens,match] = regexp(s,'Well=([A-Za-z])(\d+)','tokens','match');
        if ~isempty(tokens)
            
            token = tokens{1};
            
            add_class('Well');
            add_class('Row');
            add_class('Column');
            
            metadata.Well{i} = [token{1} token{2}];
            metadata.Row{i} = token{1};
            metadata.Column{i} = token{2};
            
            s = strrep(s,match{1},'');
            
        else  
        
        
            % Look for FOV indicator
            [match,tokens] = regexp(s,'([A-Z])-(\d)+ - FOV=?(\d{1,6})','match','tokens','once');
            if ~isempty(match)
                add_class('Well');
                add_class('FOV');

                metadata.Well{i} = [tokens{1} tokens{2}];
                metadata.Row{i} = tokens{1};
                metadata.Column{i} = tokens{2};
                metadata.FOV{i} = tokens{3};
                metadata.Well_FOV{i} = [tokens{1} tokens{2} '-' tokens{3}];

                s = strrep(s,match,'');
            else
                [match,tokens] = regexp(s,'^([A-Z]{1,2})(\d){1,2}$','match','tokens','once');

                if ~isempty(match)
                    add_class('Well');
                    add_class('Row');
                    add_class('Column');

                    metadata.Well{i} = [tokens{1} tokens{2}];
                    metadata.Row{i} = tokens{1};
                    metadata.Column{i} = tokens{2};

                    s = strrep(s,match,'');
                end
            end
        end

        % Look for things of the form 'x=nn'
        [match,tokens] = regexp(s,'(\w+)=([\d_\-,]*)(\S*)','match','tokens');
        for j=1:length(tokens)
            t = tokens{j};
            add_class(t{1})
            t{2} = strrep(t{2},'_','.');
            if strcmp(t{2},'')
                if ~isempty(t{3})
                    metadata.(t{1}){i} = t{3};
                end
            else
                metadata.(t{1}){i} = t{2};
            end
            
            s = strrep(s,match{j},'');
        end
        
        % Look for things of the form 'nnxx'
        [match,tokens] = regexp(s,'\s([\d]+(?:[_-,]\d+)*)([a-zA-Z]+)','match','tokens');
        for j=1:length(tokens)
            t = tokens{j};
            t{1} = strrep(t{1},'_','.');
            add_class(t{2})
            metadata.(t{2}){i} = t{1};
            
            s = strrep(s,match{j},'');
        end
        
        % Look for things of the form 'Xnn'
        [match,tokens] = regexp(s,'\s([A-Z][a-z]+)([\d]+(?:[_-,]\d+)*)','match','tokens');
        for j=1:length(tokens)
            t = tokens{j};
            t{2} = strrep(t{2},'_','.');
            add_class(t{1})
            metadata.(t{1}){i} = t{2};
            
            s = strrep(s,match{j},'');
        end
        
        new_strings{i} = s;
        
        common_substring = commonsubstring(common_substring,s);
        
        if size(common_substring,1) > 1
            common_substring = common_substring(1,:);
        end
    end
    
    if length(new_strings) > 1
        use_filenames = false;
        for i=1:length(new_strings)
            %new_strings{i} = strrep(new_strings{i},common_substring,'');
            if ~strcmp(new_strings{i},'')
                use_filenames = true;
            end
        end
    else
        use_filenames = (length(new_strings) == 1);
    end
    
    if use_filenames
        metadata.FileName = new_strings;
    end
    
    
    names = fieldnames(metadata);

    for j=1:length(names)

        d =  metadata.(names{j});
       
        try
            nums = cellfun(@str2num,d,'UniformOutput',true);
            metadata.(names{j}) = num2cell(nums);  
        catch %#ok
            metadata.(names{j}) = d;  
        end
    end
    
    % put rep fields at end
    fields = fieldnames(metadata);
    sel = ~cellfun(@isempty,strfind(fields,'Rep'));
    [~,idx] = sort(sel);
    ord = 1:length(fields);
    metadata = orderfields(metadata,ord(idx));

catch e

    warning('Error while trying to extract metadata! Falling back to filenames');
    metadata.FileName = strings;
    disp(getReport(e));
end

    function add_class(class)
        if ~isfield(metadata,class)
            metadata.(class) = cell(1,n);
        end
    end

end