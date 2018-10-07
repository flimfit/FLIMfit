function v = read_version
    try
        v = fileread(['GeneratedFiles' filesep 'version.txt']);
    catch
        v = '[unknown version]';
    end
end