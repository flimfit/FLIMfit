function upgrade_pattern_library()

    pattern_library = getpref('FLIMfit','pattern_library',containers.Map('KeyType','char','ValueType','any'));

    keys = pattern_library.keys;

    for i=1:length(keys)
        pattern = pattern_library(keys{i});

        if iscell(pattern)
            new_pattern = [];
            for j=1:length(pattern)
                new_pattern(:,j) = pattern{j};
            end

            pattern_library(keys{i}) = new_pattern;    
        end
    end

    setpref('FLIMfit','pattern_library',pattern_library);
