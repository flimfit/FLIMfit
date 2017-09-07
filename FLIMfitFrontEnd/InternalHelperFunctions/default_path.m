function path = default_path()
    if ispc
        platform_default_path = 'C:';
    else
        platform_default_path = '';
    end

    path = getpref('GlobalAnalysisFrontEnd','DefaultFolder',platform_default_path);
end